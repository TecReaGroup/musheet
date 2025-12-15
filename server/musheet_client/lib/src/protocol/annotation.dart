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

abstract class Annotation implements _i1.SerializableModel {
  Annotation._({
    this.id,
    required this.instrumentScoreId,
    required this.userId,
    required this.pageNumber,
    required this.type,
    required this.data,
    required this.positionX,
    required this.positionY,
    this.width,
    this.height,
    this.color,
    this.vectorClock,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Annotation({
    int? id,
    required int instrumentScoreId,
    required int userId,
    required int pageNumber,
    required String type,
    required String data,
    required double positionX,
    required double positionY,
    double? width,
    double? height,
    String? color,
    String? vectorClock,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AnnotationImpl;

  factory Annotation.fromJson(Map<String, dynamic> jsonSerialization) {
    return Annotation(
      id: jsonSerialization['id'] as int?,
      instrumentScoreId: jsonSerialization['instrumentScoreId'] as int,
      userId: jsonSerialization['userId'] as int,
      pageNumber: jsonSerialization['pageNumber'] as int,
      type: jsonSerialization['type'] as String,
      data: jsonSerialization['data'] as String,
      positionX: (jsonSerialization['positionX'] as num).toDouble(),
      positionY: (jsonSerialization['positionY'] as num).toDouble(),
      width: (jsonSerialization['width'] as num?)?.toDouble(),
      height: (jsonSerialization['height'] as num?)?.toDouble(),
      color: jsonSerialization['color'] as String?,
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

  int instrumentScoreId;

  int userId;

  int pageNumber;

  String type;

  String data;

  double positionX;

  double positionY;

  double? width;

  double? height;

  String? color;

  String? vectorClock;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Annotation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Annotation copyWith({
    int? id,
    int? instrumentScoreId,
    int? userId,
    int? pageNumber,
    String? type,
    String? data,
    double? positionX,
    double? positionY,
    double? width,
    double? height,
    String? color,
    String? vectorClock,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Annotation',
      if (id != null) 'id': id,
      'instrumentScoreId': instrumentScoreId,
      'userId': userId,
      'pageNumber': pageNumber,
      'type': type,
      'data': data,
      'positionX': positionX,
      'positionY': positionY,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (color != null) 'color': color,
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

class _AnnotationImpl extends Annotation {
  _AnnotationImpl({
    int? id,
    required int instrumentScoreId,
    required int userId,
    required int pageNumber,
    required String type,
    required String data,
    required double positionX,
    required double positionY,
    double? width,
    double? height,
    String? color,
    String? vectorClock,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         instrumentScoreId: instrumentScoreId,
         userId: userId,
         pageNumber: pageNumber,
         type: type,
         data: data,
         positionX: positionX,
         positionY: positionY,
         width: width,
         height: height,
         color: color,
         vectorClock: vectorClock,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Annotation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Annotation copyWith({
    Object? id = _Undefined,
    int? instrumentScoreId,
    int? userId,
    int? pageNumber,
    String? type,
    String? data,
    double? positionX,
    double? positionY,
    Object? width = _Undefined,
    Object? height = _Undefined,
    Object? color = _Undefined,
    Object? vectorClock = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Annotation(
      id: id is int? ? id : this.id,
      instrumentScoreId: instrumentScoreId ?? this.instrumentScoreId,
      userId: userId ?? this.userId,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      data: data ?? this.data,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      width: width is double? ? width : this.width,
      height: height is double? ? height : this.height,
      color: color is String? ? color : this.color,
      vectorClock: vectorClock is String? ? vectorClock : this.vectorClock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
