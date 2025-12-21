import 'dart:io';
import 'dart:typed_data';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';
import '../helpers/auth_helper.dart';

/// Profile endpoint for user profile management
class ProfileEndpoint extends Endpoint {
  /// Get current user profile
  Future<UserProfile> getProfile(Session session, int userId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    final user = await User.db.findById(session, validatedUserId);
    if (user == null) throw UserNotFoundException();

    // Get user's teams
    final memberships = await TeamMember.db.find(
      session,
      where: (t) => t.userId.equals(validatedUserId),
    );

    final teams = <TeamInfo>[];
    for (final m in memberships) {
      final team = await Team.db.findById(session, m.teamId);
      if (team != null) {
        teams.add(TeamInfo(
          id: team.id!,
          name: team.name,
          role: m.role,
        ));
      }
    }

    // Get storage usage
    final storage = await UserStorage.db.find(
      session,
      where: (t) => t.userId.equals(validatedUserId),
    );

    return UserProfile(
      id: validatedUserId,
      username: user.username,
      displayName: user.displayName,
      avatarUrl: user.avatarPath != null
          ? _getAvatarUrl(user.avatarPath!)
          : null,
      bio: user.bio,
      preferredInstrument: user.preferredInstrument,
      teams: teams,
      storageUsedBytes: storage.isNotEmpty ? storage.first.usedBytes : 0,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    );
  }

  /// Update profile
  Future<UserProfile> updateProfile(
    Session session,
    int userId, {
    String? displayName,
    String? bio,
    String? preferredInstrument,
  }) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    final user = await User.db.findById(session, validatedUserId);
    if (user == null) throw UserNotFoundException();

    // Update fields (only provided ones)
    if (displayName != null) user.displayName = displayName;
    if (bio != null) user.bio = bio;
    if (preferredInstrument != null) user.preferredInstrument = preferredInstrument;
    user.updatedAt = DateTime.now();

    await User.db.updateRow(session, user);

    return await getProfile(session, validatedUserId);
  }

  /// Upload avatar
  Future<AvatarUploadResult> uploadAvatar(
    Session session,
    int userId,
    ByteData imageData,
    String fileName,
  ) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    // Validate file type
    final extension = fileName.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      throw InvalidImageFormatException();
    }

    // Validate file size (max 2MB)
    if (imageData.lengthInBytes > 2 * 1024 * 1024) {
      throw ImageTooLargeException();
    }

    // Delete old avatar
    final user = await User.db.findById(session, validatedUserId);
    if (user == null) throw UserNotFoundException();
    
    if (user.avatarPath != null) {
      await _deleteFile(user.avatarPath!);
    }

    // Save new avatar (generate unique filename)
    final uniqueName = '${validatedUserId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = 'avatars/$uniqueName';
    await _saveFile(path, imageData);

    // Update user record
    user.avatarPath = path;
    user.updatedAt = DateTime.now();
    await User.db.updateRow(session, user);

    return AvatarUploadResult(
      success: true,
      avatarUrl: _getAvatarUrl(path),
      thumbnailUrl: _getAvatarUrl(path),
    );
  }

  /// Delete avatar
  Future<bool> deleteAvatar(Session session, int userId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    final user = await User.db.findById(session, validatedUserId);
    if (user == null || user.avatarPath == null) return false;

    // Delete file
    await _deleteFile(user.avatarPath!);

    // Clear avatar path
    user.avatarPath = null;
    user.updatedAt = DateTime.now();
    await User.db.updateRow(session, user);

    return true;
  }

  /// Get other user's public profile (visible to team members)
  Future<PublicUserProfile> getPublicProfile(Session session, int userId, int targetUserId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    // Check if they share a team
    final myTeams = await TeamMember.db.find(
      session,
      where: (t) => t.userId.equals(validatedUserId),
    );
    final targetTeams = await TeamMember.db.find(
      session,
      where: (t) => t.userId.equals(targetUserId),
    );

    final myTeamIds = myTeams.map((t) => t.teamId).toSet();
    final targetTeamIds = targetTeams.map((t) => t.teamId).toSet();
    final commonTeams = myTeamIds.intersection(targetTeamIds);

    if (commonTeams.isEmpty) {
      throw PermissionDeniedException('No common teams, cannot view profile');
    }

    final user = await User.db.findById(session, targetUserId);
    if (user == null) throw UserNotFoundException();

    return PublicUserProfile(
      id: user.id!,
      username: user.username,
      displayName: user.displayName,
      avatarUrl: user.avatarPath != null ? _getAvatarUrl(user.avatarPath!) : null,
      bio: user.bio,
      preferredInstrument: user.preferredInstrument,
    );
  }

  /// Delete all user data (DEBUG ONLY - use with caution!)
  /// This removes all scores, instrument scores, annotations, setlists, and user storage data
  Future<DeleteUserDataResult> deleteAllUserData(Session session, int userId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    session.log('[PROFILE] ⚠️ DELETE ALL USER DATA called for userId: $validatedUserId', level: LogLevel.warning);

    int deletedScores = 0;
    int deletedInstrumentScores = 0;
    int deletedAnnotations = 0;
    int deletedSetlists = 0;
    int deletedSetlistScores = 0;

    // 1. Get all user scores
    final scores = await Score.db.find(
      session,
      where: (t) => t.userId.equals(validatedUserId),
    );
    session.log('[PROFILE] Found ${scores.length} scores to delete', level: LogLevel.info);

    // 2. For each score, delete annotations, instrument scores, and PDFs
    for (final score in scores) {
      // Get instrument scores for this score
      final instrumentScores = await InstrumentScore.db.find(
        session,
        where: (t) => t.scoreId.equals(score.id!),
      );

      // Delete annotations for each instrument score
      for (final is_ in instrumentScores) {
        final deletedAnns = await Annotation.db.deleteWhere(
          session,
          where: (t) => t.instrumentScoreId.equals(is_.id!),
        );
        deletedAnnotations += deletedAnns.length;

        // Delete PDF file if exists
        if (is_.pdfPath != null) {
          await _deleteFile(is_.pdfPath!);
        }
      }

      // Delete instrument scores
      final deletedIS = await InstrumentScore.db.deleteWhere(
        session,
        where: (t) => t.scoreId.equals(score.id!),
      );
      deletedInstrumentScores += deletedIS.length;
    }

    // 3. Delete all scores
    final deletedScoresList = await Score.db.deleteWhere(
      session,
      where: (t) => t.userId.equals(validatedUserId),
    );
    deletedScores = deletedScoresList.length;

    // 4. Delete setlist scores
    final setlists = await Setlist.db.find(
      session,
      where: (t) => t.userId.equals(validatedUserId),
    );
    
    for (final setlist in setlists) {
      final deletedSS = await SetlistScore.db.deleteWhere(
        session,
        where: (t) => t.setlistId.equals(setlist.id!),
      );
      deletedSetlistScores += deletedSS.length;
    }

    // 5. Delete setlists
    final deletedSetlistsList = await Setlist.db.deleteWhere(
      session,
      where: (t) => t.userId.equals(validatedUserId),
    );
    deletedSetlists = deletedSetlistsList.length;

    // 6. Reset user storage
    await UserStorage.db.deleteWhere(
      session,
      where: (t) => t.userId.equals(validatedUserId),
    );

    session.log('[PROFILE] Deleted: scores=$deletedScores, instrumentScores=$deletedInstrumentScores, '
        'annotations=$deletedAnnotations, setlists=$deletedSetlists, setlistScores=$deletedSetlistScores',
        level: LogLevel.info);

    return DeleteUserDataResult(
      success: true,
      deletedScores: deletedScores,
      deletedInstrumentScores: deletedInstrumentScores,
      deletedAnnotations: deletedAnnotations,
      deletedSetlists: deletedSetlists,
      deletedSetlistScores: deletedSetlistScores,
    );
  }

  // === Helper methods ===

  String _getAvatarUrl(String path) {
    final serverUrl = Platform.environment['SERVER_URL'] ?? 'http://localhost:8080';
    return '$serverUrl/files/$path';
  }

  Future<void> _saveFile(String path, ByteData data) async {
    final uploadsDir = Directory('uploads');
    if (!await uploadsDir.exists()) {
      await uploadsDir.create(recursive: true);
    }
    
    final file = File('uploads/$path');
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    await file.writeAsBytes(data.buffer.asUint8List());
  }

  Future<void> _deleteFile(String path) async {
    final file = File('uploads/$path');
    if (await file.exists()) {
      await file.delete();
    }
  }
}