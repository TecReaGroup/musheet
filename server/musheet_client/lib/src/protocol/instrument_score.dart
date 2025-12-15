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

abstract class InstrumentScore implements _i1.SerializableModel {
  InstrumentScore._({
    this.id,
    required this.scoreId,
    required this.instrumentName,
    this.pdfPath,
    this.pdfHash,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstrumentScore({
    int? id,
    required int scoreId,
    required String instrumentName,
    String? pdfPath,
    String? pdfHash,
    required int orderIndex,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _InstrumentScoreImpl;

  factory InstrumentScore.fromJson(Map<String, dynamic> jsonSerialization) {
    return InstrumentScore(
      id: jsonSerialization['id'] as int?,
      scoreId: jsonSerialization['scoreId'] as int,
      instrumentName: jsonSerialization['instrumentName'] as String,
      pdfPath: jsonSerialization['pdfPath'] as String?,
      pdfHash: jsonSerialization['pdfHash'] as String?,
      orderIndex: jsonSerialization['orderIndex'] as int,
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

  int scoreId;

  String instrumentName;

  String? pdfPath;

  String? pdfHash;

  int orderIndex;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [InstrumentScore]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  InstrumentScore copyWith({
    int? id,
    int? scoreId,
    String? instrumentName,
    String? pdfPath,
    String? pdfHash,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InstrumentScore',
      if (id != null) 'id': id,
      'scoreId': scoreId,
      'instrumentName': instrumentName,
      if (pdfPath != null) 'pdfPath': pdfPath,
      if (pdfHash != null) 'pdfHash': pdfHash,
      'orderIndex': orderIndex,
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

class _InstrumentScoreImpl extends InstrumentScore {
  _InstrumentScoreImpl({
    int? id,
    required int scoreId,
    required String instrumentName,
    String? pdfPath,
    String? pdfHash,
    required int orderIndex,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         scoreId: scoreId,
         instrumentName: instrumentName,
         pdfPath: pdfPath,
         pdfHash: pdfHash,
         orderIndex: orderIndex,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [InstrumentScore]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  InstrumentScore copyWith({
    Object? id = _Undefined,
    int? scoreId,
    String? instrumentName,
    Object? pdfPath = _Undefined,
    Object? pdfHash = _Undefined,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstrumentScore(
      id: id is int? ? id : this.id,
      scoreId: scoreId ?? this.scoreId,
      instrumentName: instrumentName ?? this.instrumentName,
      pdfPath: pdfPath is String? ? pdfPath : this.pdfPath,
      pdfHash: pdfHash is String? ? pdfHash : this.pdfHash,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
