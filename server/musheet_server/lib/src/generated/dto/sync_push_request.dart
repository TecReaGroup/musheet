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
import 'package:serverpod/serverpod.dart' as _i1;
import '../dto/sync_entity_change.dart' as _i2;
import 'package:musheet_server/src/generated/protocol.dart' as _i3;

/// Sync Push Request DTO
/// Unified push request for all entity changes
abstract class SyncPushRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SyncPushRequest._({
    required this.clientLibraryVersion,
    this.scores,
    this.instrumentScores,
    this.annotations,
    this.setlists,
    this.setlistScores,
    this.deletes,
  });

  factory SyncPushRequest({
    required int clientLibraryVersion,
    List<_i2.SyncEntityChange>? scores,
    List<_i2.SyncEntityChange>? instrumentScores,
    List<_i2.SyncEntityChange>? annotations,
    List<_i2.SyncEntityChange>? setlists,
    List<_i2.SyncEntityChange>? setlistScores,
    List<String>? deletes,
  }) = _SyncPushRequestImpl;

  factory SyncPushRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncPushRequest(
      clientLibraryVersion: jsonSerialization['clientLibraryVersion'] as int,
      scores: jsonSerialization['scores'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.SyncEntityChange>>(
              jsonSerialization['scores'],
            ),
      instrumentScores: jsonSerialization['instrumentScores'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.SyncEntityChange>>(
              jsonSerialization['instrumentScores'],
            ),
      annotations: jsonSerialization['annotations'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.SyncEntityChange>>(
              jsonSerialization['annotations'],
            ),
      setlists: jsonSerialization['setlists'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.SyncEntityChange>>(
              jsonSerialization['setlists'],
            ),
      setlistScores: jsonSerialization['setlistScores'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.SyncEntityChange>>(
              jsonSerialization['setlistScores'],
            ),
      deletes: jsonSerialization['deletes'] == null
          ? null
          : _i3.Protocol().deserialize<List<String>>(
              jsonSerialization['deletes'],
            ),
    );
  }

  /// Client's current library version (for conflict detection)
  int clientLibraryVersion;

  /// List of score changes
  List<_i2.SyncEntityChange>? scores;

  /// List of instrument score changes
  List<_i2.SyncEntityChange>? instrumentScores;

  /// List of annotation changes
  List<_i2.SyncEntityChange>? annotations;

  /// List of setlist changes
  List<_i2.SyncEntityChange>? setlists;

  /// List of setlist score changes
  List<_i2.SyncEntityChange>? setlistScores;

  /// List of entity IDs to delete (format: "type:id")
  List<String>? deletes;

  /// Returns a shallow copy of this [SyncPushRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncPushRequest copyWith({
    int? clientLibraryVersion,
    List<_i2.SyncEntityChange>? scores,
    List<_i2.SyncEntityChange>? instrumentScores,
    List<_i2.SyncEntityChange>? annotations,
    List<_i2.SyncEntityChange>? setlists,
    List<_i2.SyncEntityChange>? setlistScores,
    List<String>? deletes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncPushRequest',
      'clientLibraryVersion': clientLibraryVersion,
      if (scores != null)
        'scores': scores?.toJson(valueToJson: (v) => v.toJson()),
      if (instrumentScores != null)
        'instrumentScores': instrumentScores?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
      if (annotations != null)
        'annotations': annotations?.toJson(valueToJson: (v) => v.toJson()),
      if (setlists != null)
        'setlists': setlists?.toJson(valueToJson: (v) => v.toJson()),
      if (setlistScores != null)
        'setlistScores': setlistScores?.toJson(valueToJson: (v) => v.toJson()),
      if (deletes != null) 'deletes': deletes?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SyncPushRequest',
      'clientLibraryVersion': clientLibraryVersion,
      if (scores != null)
        'scores': scores?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (instrumentScores != null)
        'instrumentScores': instrumentScores?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (annotations != null)
        'annotations': annotations?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (setlists != null)
        'setlists': setlists?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (setlistScores != null)
        'setlistScores': setlistScores?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (deletes != null) 'deletes': deletes?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SyncPushRequestImpl extends SyncPushRequest {
  _SyncPushRequestImpl({
    required int clientLibraryVersion,
    List<_i2.SyncEntityChange>? scores,
    List<_i2.SyncEntityChange>? instrumentScores,
    List<_i2.SyncEntityChange>? annotations,
    List<_i2.SyncEntityChange>? setlists,
    List<_i2.SyncEntityChange>? setlistScores,
    List<String>? deletes,
  }) : super._(
         clientLibraryVersion: clientLibraryVersion,
         scores: scores,
         instrumentScores: instrumentScores,
         annotations: annotations,
         setlists: setlists,
         setlistScores: setlistScores,
         deletes: deletes,
       );

  /// Returns a shallow copy of this [SyncPushRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncPushRequest copyWith({
    int? clientLibraryVersion,
    Object? scores = _Undefined,
    Object? instrumentScores = _Undefined,
    Object? annotations = _Undefined,
    Object? setlists = _Undefined,
    Object? setlistScores = _Undefined,
    Object? deletes = _Undefined,
  }) {
    return SyncPushRequest(
      clientLibraryVersion: clientLibraryVersion ?? this.clientLibraryVersion,
      scores: scores is List<_i2.SyncEntityChange>?
          ? scores
          : this.scores?.map((e0) => e0.copyWith()).toList(),
      instrumentScores: instrumentScores is List<_i2.SyncEntityChange>?
          ? instrumentScores
          : this.instrumentScores?.map((e0) => e0.copyWith()).toList(),
      annotations: annotations is List<_i2.SyncEntityChange>?
          ? annotations
          : this.annotations?.map((e0) => e0.copyWith()).toList(),
      setlists: setlists is List<_i2.SyncEntityChange>?
          ? setlists
          : this.setlists?.map((e0) => e0.copyWith()).toList(),
      setlistScores: setlistScores is List<_i2.SyncEntityChange>?
          ? setlistScores
          : this.setlistScores?.map((e0) => e0.copyWith()).toList(),
      deletes: deletes is List<String>?
          ? deletes
          : this.deletes?.map((e0) => e0).toList(),
    );
  }
}
