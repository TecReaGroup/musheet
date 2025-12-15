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

abstract class SetlistScore implements _i1.SerializableModel {
  SetlistScore._({
    this.id,
    required this.setlistId,
    required this.scoreId,
    required this.orderIndex,
  });

  factory SetlistScore({
    int? id,
    required int setlistId,
    required int scoreId,
    required int orderIndex,
  }) = _SetlistScoreImpl;

  factory SetlistScore.fromJson(Map<String, dynamic> jsonSerialization) {
    return SetlistScore(
      id: jsonSerialization['id'] as int?,
      setlistId: jsonSerialization['setlistId'] as int,
      scoreId: jsonSerialization['scoreId'] as int,
      orderIndex: jsonSerialization['orderIndex'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int setlistId;

  int scoreId;

  int orderIndex;

  /// Returns a shallow copy of this [SetlistScore]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SetlistScore copyWith({
    int? id,
    int? setlistId,
    int? scoreId,
    int? orderIndex,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SetlistScore',
      if (id != null) 'id': id,
      'setlistId': setlistId,
      'scoreId': scoreId,
      'orderIndex': orderIndex,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SetlistScoreImpl extends SetlistScore {
  _SetlistScoreImpl({
    int? id,
    required int setlistId,
    required int scoreId,
    required int orderIndex,
  }) : super._(
         id: id,
         setlistId: setlistId,
         scoreId: scoreId,
         orderIndex: orderIndex,
       );

  /// Returns a shallow copy of this [SetlistScore]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SetlistScore copyWith({
    Object? id = _Undefined,
    int? setlistId,
    int? scoreId,
    int? orderIndex,
  }) {
    return SetlistScore(
      id: id is int? ? id : this.id,
      setlistId: setlistId ?? this.setlistId,
      scoreId: scoreId ?? this.scoreId,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
