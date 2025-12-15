import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';

/// Team annotation endpoint for team shared annotation management
class TeamAnnotationEndpoint extends Endpoint {
  /// Get annotations for a team score
  Future<List<TeamAnnotation>> getTeamAnnotations(
    Session session,
    int userId,
    int teamScoreId,
  ) async {
    // Verify access to team score
    final teamScore = await TeamScore.db.findById(session, teamScoreId);
    if (teamScore == null) {
      throw NotFoundException('Team score not found');
    }

    if (!await _isTeamMember(session, teamScore.teamId, userId)) {
      throw NotTeamMemberException();
    }

    return await TeamAnnotation.db.find(
      session,
      where: (t) => t.teamScoreId.equals(teamScoreId),
    );
  }

  /// Add annotation to team score
  Future<TeamAnnotation> addTeamAnnotation(
    Session session,
    int userId,
    int teamScoreId,
    int instrumentScoreId,
    int pageNumber,
    String type,
    String data,
    double positionX,
    double positionY,
  ) async {
    // Verify access to team score
    final teamScore = await TeamScore.db.findById(session, teamScoreId);
    if (teamScore == null) {
      throw NotFoundException('Team score not found');
    }

    if (!await _isTeamMember(session, teamScore.teamId, userId)) {
      throw NotTeamMemberException();
    }

    final annotation = TeamAnnotation(
      teamScoreId: teamScoreId,
      instrumentScoreId: instrumentScoreId,
      pageNumber: pageNumber,
      type: type,
      data: data,
      positionX: positionX,
      positionY: positionY,
      createdBy: userId,
      updatedBy: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await TeamAnnotation.db.insertRow(session, annotation);
  }

  /// Update team annotation
  Future<TeamAnnotation> updateTeamAnnotation(
    Session session,
    int userId,
    int annotationId,
    String data,
    double positionX,
    double positionY,
  ) async {
    final annotation = await TeamAnnotation.db.findById(session, annotationId);
    if (annotation == null) {
      throw NotFoundException('Annotation not found');
    }

    // Only creator can update
    if (annotation.createdBy != userId) {
      throw PermissionDeniedException('Only creator can update annotation');
    }

    annotation.data = data;
    annotation.positionX = positionX;
    annotation.positionY = positionY;
    annotation.updatedBy = userId;
    annotation.updatedAt = DateTime.now();

    return await TeamAnnotation.db.updateRow(session, annotation);
  }

  /// Delete team annotation
  Future<bool> deleteTeamAnnotation(
    Session session,
    int userId,
    int annotationId,
  ) async {
    final annotation = await TeamAnnotation.db.findById(session, annotationId);
    if (annotation == null) return false;

    // Get team score to check admin access
    final teamScore = await TeamScore.db.findById(session, annotation.teamScoreId);
    if (teamScore == null) return false;

    // Only creator or team admin can delete
    final isCreator = annotation.createdBy == userId;
    final isTeamAdmin = await _isTeamAdmin(session, teamScore.teamId, userId);

    if (!isCreator && !isTeamAdmin) {
      throw PermissionDeniedException('Only creator or admin can delete annotation');
    }

    await TeamAnnotation.db.deleteRow(session, annotation);
    return true;
  }

  // === Helper Methods ===

  Future<bool> _isTeamMember(Session session, int teamId, int userId) async {
    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.userId.equals(userId),
    );
    return members.isNotEmpty;
  }

  Future<bool> _isTeamAdmin(Session session, int teamId, int userId) async {
    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.userId.equals(userId),
    );
    return members.isNotEmpty && members.first.role == 'admin';
  }
}