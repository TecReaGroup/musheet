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

abstract class Score implements _i1.SerializableModel {
  Score._({
    this.id,
    required this.userId,
    required this.title,
    this.composer,
    this.bpm,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.version,
    this.syncStatus,
  });

  factory Score({
    int? id,
    required int userId,
    required String title,
    String? composer,
    int? bpm,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required int version,
    String? syncStatus,
  }) = _ScoreImpl;

  factory Score.fromJson(Map<String, dynamic> jsonSerialization) {
    return Score(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      title: jsonSerialization['title'] as String,
      composer: jsonSerialization['composer'] as String?,
      bpm: jsonSerialization['bpm'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
      version: jsonSerialization['version'] as int,
      syncStatus: jsonSerialization['syncStatus'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  String title;

  String? composer;

  int? bpm;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  int version;

  String? syncStatus;

  /// Returns a shallow copy of this [Score]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Score copyWith({
    int? id,
    int? userId,
    String? title,
    String? composer,
    int? bpm,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
    String? syncStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Score',
      if (id != null) 'id': id,
      'userId': userId,
      'title': title,
      if (composer != null) 'composer': composer,
      if (bpm != null) 'bpm': bpm,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      'version': version,
      if (syncStatus != null) 'syncStatus': syncStatus,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ScoreImpl extends Score {
  _ScoreImpl({
    int? id,
    required int userId,
    required String title,
    String? composer,
    int? bpm,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required int version,
    String? syncStatus,
  }) : super._(
         id: id,
         userId: userId,
         title: title,
         composer: composer,
         bpm: bpm,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
         version: version,
         syncStatus: syncStatus,
       );

  /// Returns a shallow copy of this [Score]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Score copyWith({
    Object? id = _Undefined,
    int? userId,
    String? title,
    Object? composer = _Undefined,
    Object? bpm = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
    int? version,
    Object? syncStatus = _Undefined,
  }) {
    return Score(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      composer: composer is String? ? composer : this.composer,
      bpm: bpm is int? ? bpm : this.bpm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
      version: version ?? this.version,
      syncStatus: syncStatus is String? ? syncStatus : this.syncStatus,
    );
  }
}
