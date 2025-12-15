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

abstract class TeamScore implements _i1.SerializableModel {
  TeamScore._({
    this.id,
    required this.teamId,
    required this.scoreId,
    required this.sharedById,
    required this.sharedAt,
  });

  factory TeamScore({
    int? id,
    required int teamId,
    required int scoreId,
    required int sharedById,
    required DateTime sharedAt,
  }) = _TeamScoreImpl;

  factory TeamScore.fromJson(Map<String, dynamic> jsonSerialization) {
    return TeamScore(
      id: jsonSerialization['id'] as int?,
      teamId: jsonSerialization['teamId'] as int,
      scoreId: jsonSerialization['scoreId'] as int,
      sharedById: jsonSerialization['sharedById'] as int,
      sharedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['sharedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int teamId;

  int scoreId;

  int sharedById;

  DateTime sharedAt;

  /// Returns a shallow copy of this [TeamScore]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamScore copyWith({
    int? id,
    int? teamId,
    int? scoreId,
    int? sharedById,
    DateTime? sharedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamScore',
      if (id != null) 'id': id,
      'teamId': teamId,
      'scoreId': scoreId,
      'sharedById': sharedById,
      'sharedAt': sharedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TeamScoreImpl extends TeamScore {
  _TeamScoreImpl({
    int? id,
    required int teamId,
    required int scoreId,
    required int sharedById,
    required DateTime sharedAt,
  }) : super._(
         id: id,
         teamId: teamId,
         scoreId: scoreId,
         sharedById: sharedById,
         sharedAt: sharedAt,
       );

  /// Returns a shallow copy of this [TeamScore]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamScore copyWith({
    Object? id = _Undefined,
    int? teamId,
    int? scoreId,
    int? sharedById,
    DateTime? sharedAt,
  }) {
    return TeamScore(
      id: id is int? ? id : this.id,
      teamId: teamId ?? this.teamId,
      scoreId: scoreId ?? this.scoreId,
      sharedById: sharedById ?? this.sharedById,
      sharedAt: sharedAt ?? this.sharedAt,
    );
  }
}
