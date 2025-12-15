/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import '../dto/team_info.dart' as _i2;
import 'package:musheet_client/src/protocol/protocol.dart' as _i3;

abstract class UserProfile implements _i1.SerializableModel {
  UserProfile._({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.preferredInstrument,
    required this.teams,
    required this.storageUsedBytes,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserProfile({
    required int id,
    required String username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? preferredInstrument,
    required List<_i2.TeamInfo> teams,
    required int storageUsedBytes,
    required DateTime createdAt,
    DateTime? lastLoginAt,
  }) = _UserProfileImpl;

  factory UserProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserProfile(
      id: jsonSerialization['id'] as int,
      username: jsonSerialization['username'] as String,
      displayName: jsonSerialization['displayName'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      bio: jsonSerialization['bio'] as String?,
      preferredInstrument: jsonSerialization['preferredInstrument'] as String?,
      teams: _i3.Protocol().deserialize<List<_i2.TeamInfo>>(
        jsonSerialization['teams'],
      ),
      storageUsedBytes: jsonSerialization['storageUsedBytes'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastLoginAt: jsonSerialization['lastLoginAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastLoginAt'],
            ),
    );
  }

  int id;

  String username;

  String? displayName;

  String? avatarUrl;

  String? bio;

  String? preferredInstrument;

  List<_i2.TeamInfo> teams;

  int storageUsedBytes;

  DateTime createdAt;

  DateTime? lastLoginAt;

  /// Returns a shallow copy of this [UserProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserProfile copyWith({
    int? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? preferredInstrument,
    List<_i2.TeamInfo>? teams,
    int? storageUsedBytes,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserProfile',
      'id': id,
      'username': username,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (bio != null) 'bio': bio,
      if (preferredInstrument != null)
        'preferredInstrument': preferredInstrument,
      'teams': teams.toJson(valueToJson: (v) => v.toJson()),
      'storageUsedBytes': storageUsedBytes,
      'createdAt': createdAt.toJson(),
      if (lastLoginAt != null) 'lastLoginAt': lastLoginAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserProfileImpl extends UserProfile {
  _UserProfileImpl({
    required int id,
    required String username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? preferredInstrument,
    required List<_i2.TeamInfo> teams,
    required int storageUsedBytes,
    required DateTime createdAt,
    DateTime? lastLoginAt,
  }) : super._(
         id: id,
         username: username,
         displayName: displayName,
         avatarUrl: avatarUrl,
         bio: bio,
         preferredInstrument: preferredInstrument,
         teams: teams,
         storageUsedBytes: storageUsedBytes,
         createdAt: createdAt,
         lastLoginAt: lastLoginAt,
       );

  /// Returns a shallow copy of this [UserProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserProfile copyWith({
    int? id,
    String? username,
    Object? displayName = _Undefined,
    Object? avatarUrl = _Undefined,
    Object? bio = _Undefined,
    Object? preferredInstrument = _Undefined,
    List<_i2.TeamInfo>? teams,
    int? storageUsedBytes,
    DateTime? createdAt,
    Object? lastLoginAt = _Undefined,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      bio: bio is String? ? bio : this.bio,
      preferredInstrument: preferredInstrument is String?
          ? preferredInstrument
          : this.preferredInstrument,
      teams: teams ?? this.teams.map((e0) => e0.copyWith()).toList(),
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt is DateTime? ? lastLoginAt : this.lastLoginAt,
    );
  }
}
