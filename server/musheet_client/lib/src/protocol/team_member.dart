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

abstract class TeamMember implements _i1.SerializableModel {
  TeamMember._({
    this.id,
    required this.teamId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  factory TeamMember({
    int? id,
    required int teamId,
    required int userId,
    required String role,
    required DateTime joinedAt,
  }) = _TeamMemberImpl;

  factory TeamMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return TeamMember(
      id: jsonSerialization['id'] as int?,
      teamId: jsonSerialization['teamId'] as int,
      userId: jsonSerialization['userId'] as int,
      role: jsonSerialization['role'] as String,
      joinedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int teamId;

  int userId;

  String role;

  DateTime joinedAt;

  /// Returns a shallow copy of this [TeamMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamMember copyWith({
    int? id,
    int? teamId,
    int? userId,
    String? role,
    DateTime? joinedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamMember',
      if (id != null) 'id': id,
      'teamId': teamId,
      'userId': userId,
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

class _TeamMemberImpl extends TeamMember {
  _TeamMemberImpl({
    int? id,
    required int teamId,
    required int userId,
    required String role,
    required DateTime joinedAt,
  }) : super._(
         id: id,
         teamId: teamId,
         userId: userId,
         role: role,
         joinedAt: joinedAt,
       );

  /// Returns a shallow copy of this [TeamMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamMember copyWith({
    Object? id = _Undefined,
    int? teamId,
    int? userId,
    String? role,
    DateTime? joinedAt,
  }) {
    return TeamMember(
      id: id is int? ? id : this.id,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
