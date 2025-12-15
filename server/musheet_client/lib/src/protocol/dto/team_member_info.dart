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

abstract class TeamMemberInfo implements _i1.SerializableModel {
  TeamMemberInfo._({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  factory TeamMemberInfo({
    required int userId,
    required String username,
    String? displayName,
    String? avatarUrl,
    required String role,
    required DateTime joinedAt,
  }) = _TeamMemberInfoImpl;

  factory TeamMemberInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return TeamMemberInfo(
      userId: jsonSerialization['userId'] as int,
      username: jsonSerialization['username'] as String,
      displayName: jsonSerialization['displayName'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      role: jsonSerialization['role'] as String,
      joinedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
    );
  }

  int userId;

  String username;

  String? displayName;

  String? avatarUrl;

  String role;

  DateTime joinedAt;

  /// Returns a shallow copy of this [TeamMemberInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamMemberInfo copyWith({
    int? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? role,
    DateTime? joinedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamMemberInfo',
      'userId': userId,
      'username': username,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'role': role,
      'joinedAt': joinedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TeamMemberInfoImpl extends TeamMemberInfo {
  _TeamMemberInfoImpl({
    required int userId,
    required String username,
    String? displayName,
    String? avatarUrl,
    required String role,
    required DateTime joinedAt,
  }) : super._(
         userId: userId,
         username: username,
         displayName: displayName,
         avatarUrl: avatarUrl,
         role: role,
         joinedAt: joinedAt,
       );

  /// Returns a shallow copy of this [TeamMemberInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamMemberInfo copyWith({
    int? userId,
    String? username,
    Object? displayName = _Undefined,
    Object? avatarUrl = _Undefined,
    String? role,
    DateTime? joinedAt,
  }) {
    return TeamMemberInfo(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
