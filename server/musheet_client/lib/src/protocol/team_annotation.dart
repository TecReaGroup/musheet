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

abstract class TeamAnnotation implements _i1.SerializableModel {
  TeamAnnotation._({
    this.id,
    required this.teamScoreId,
    required this.instrumentScoreId,
    required this.pageNumber,
    required this.type,
    required this.data,
    required this.positionX,
    required this.positionY,
    required this.createdBy,
    required this.updatedBy,
    this.vectorClock,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamAnnotation({
    int? id,
    required int teamScoreId,
    required int instrumentScoreId,
    required int pageNumber,
    required String type,
    required String data,
    required double positionX,
    required double positionY,
    required int createdBy,
    required int updatedBy,
    String? vectorClock,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TeamAnnotationImpl;

  factory TeamAnnotation.fromJson(Map<String, dynamic> jsonSerialization) {
    return TeamAnnotation(
      id: jsonSerialization['id'] as int?,
      teamScoreId: jsonSerialization['teamScoreId'] as int,
      instrumentScoreId: jsonSerialization['instrumentScoreId'] as int,
      pageNumber: jsonSerialization['pageNumber'] as int,
      type: jsonSerialization['type'] as String,
      data: jsonSerialization['data'] as String,
      positionX: (jsonSerialization['positionX'] as num).toDouble(),
      positionY: (jsonSerialization['positionY'] as num).toDouble(),
      createdBy: jsonSerialization['createdBy'] as int,
      updatedBy: jsonSerialization['updatedBy'] as int,
      vectorClock: jsonSerialization['vectorClock'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int teamScoreId;

  int instrumentScoreId;

  int pageNumber;

  String type;

  String data;

  double positionX;

  double positionY;

  int createdBy;

  int updatedBy;

  String? vectorClock;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [TeamAnnotation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamAnnotation copyWith({
    int? id,
    int? teamScoreId,
    int? instrumentScoreId,
    int? pageNumber,
    String? type,
    String? data,
    double? positionX,
    double? positionY,
    int? createdBy,
    int? updatedBy,
    String? vectorClock,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamAnnotation',
      if (id != null) 'id': id,
      'teamScoreId': teamScoreId,
      'instrumentScoreId': instrumentScoreId,
      'pageNumber': pageNumber,
      'type': type,
      'data': data,
      'positionX': positionX,
      'positionY': positionY,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      if (vectorClock != null) 'vectorClock': vectorClock,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TeamAnnotationImpl extends TeamAnnotation {
  _TeamAnnotationImpl({
    int? id,
    required int teamScoreId,
    required int instrumentScoreId,
    required int pageNumber,
    required String type,
    required String data,
    required double positionX,
    required double positionY,
    required int createdBy,
    required int updatedBy,
    String? vectorClock,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         teamScoreId: teamScoreId,
         instrumentScoreId: instrumentScoreId,
         pageNumber: pageNumber,
         type: type,
         data: data,
         positionX: positionX,
         positionY: positionY,
         createdBy: createdBy,
         updatedBy: updatedBy,
         vectorClock: vectorClock,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [TeamAnnotation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamAnnotation copyWith({
    Object? id = _Undefined,
    int? teamScoreId,
    int? instrumentScoreId,
    int? pageNumber,
    String? type,
    String? data,
    double? positionX,
    double? positionY,
    int? createdBy,
    int? updatedBy,
    Object? vectorClock = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamAnnotation(
      id: id is int? ? id : this.id,
      teamScoreId: teamScoreId ?? this.teamScoreId,
      instrumentScoreId: instrumentScoreId ?? this.instrumentScoreId,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      data: data ?? this.data,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      vectorClock: vectorClock is String? ? vectorClock : this.vectorClock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
