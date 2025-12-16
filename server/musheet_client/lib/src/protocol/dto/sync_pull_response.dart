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
import '../dto/sync_entity_data.dart' as _i2;
import 'package:musheet_client/src/protocol/protocol.dart' as _i3;

/// Sync Pull Response DTO
/// Response from pull operation containing all changes since requested version
abstract class SyncPullResponse implements _i1.SerializableModel {
  SyncPullResponse._({
    required this.libraryVersion,
    this.scores,
    this.instrumentScores,
    this.annotations,
    this.setlists,
    this.setlistScores,
    this.deleted,
    required this.isFullSync,
  });

  factory SyncPullResponse({
    required int libraryVersion,
    List<_i2.SyncEntityData>? scores,
    List<_i2.SyncEntityData>? instrumentScores,
    List<_i2.SyncEntityData>? annotations,
    List<_i2.SyncEntityData>? setlists,
    List<_i2.SyncEntityData>? setlistScores,
    List<String>? deleted,
    required bool isFullSync,
  }) = _SyncPullResponseImpl;

  factory SyncPullResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncPullResponse(
      libraryVersion: jsonSerialization['libraryVersion'] as int,
      scores: jsonSerialization['scores'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.SyncEntityData>>(
              jsonSerialization['scores'],
            ),
      instrumentScores: jsonSerialization['instrumentScores'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.SyncEntityData>>(
              jsonSerialization['instrumentScores'],
            ),
      annotations: jsonSerialization['annotations'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.SyncEntityData>>(
              jsonSerialization['annotations'],
            ),
      setlists: jsonSerialization['setlists'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.SyncEntityData>>(
              jsonSerialization['setlists'],
            ),
      setlistScores: jsonSerialization['setlistScores'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.SyncEntityData>>(
              jsonSerialization['setlistScores'],
            ),
      deleted: jsonSerialization['deleted'] == null
          ? null
          : _i3.Protocol().deserialize<List<String>>(
              jsonSerialization['deleted'],
            ),
      isFullSync: jsonSerialization['isFullSync'] as bool,
    );
  }

  /// Current library version on server
  int libraryVersion;

  /// Score changes since requested version
  List<_i2.SyncEntityData>? scores;

  /// Instrument score changes since requested version
  List<_i2.SyncEntityData>? instrumentScores;

  /// Annotation changes since requested version
  List<_i2.SyncEntityData>? annotations;

  /// Setlist changes since requested version
  List<_i2.SyncEntityData>? setlists;

  /// Setlist score changes since requested version
  List<_i2.SyncEntityData>? setlistScores;

  /// List of deleted entity IDs (format: "type:serverId")
  List<String>? deleted;

  /// Whether this is a full sync (client was at version 0)
  bool isFullSync;

  /// Returns a shallow copy of this [SyncPullResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncPullResponse copyWith({
    int? libraryVersion,
    List<_i2.SyncEntityData>? scores,
    List<_i2.SyncEntityData>? instrumentScores,
    List<_i2.SyncEntityData>? annotations,
    List<_i2.SyncEntityData>? setlists,
    List<_i2.SyncEntityData>? setlistScores,
    List<String>? deleted,
    bool? isFullSync,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncPullResponse',
      'libraryVersion': libraryVersion,
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
      if (deleted != null) 'deleted': deleted?.toJson(),
      'isFullSync': isFullSync,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SyncPullResponseImpl extends SyncPullResponse {
  _SyncPullResponseImpl({
    required int libraryVersion,
    List<_i2.SyncEntityData>? scores,
    List<_i2.SyncEntityData>? instrumentScores,
    List<_i2.SyncEntityData>? annotations,
    List<_i2.SyncEntityData>? setlists,
    List<_i2.SyncEntityData>? setlistScores,
    List<String>? deleted,
    required bool isFullSync,
  }) : super._(
         libraryVersion: libraryVersion,
         scores: scores,
         instrumentScores: instrumentScores,
         annotations: annotations,
         setlists: setlists,
         setlistScores: setlistScores,
         deleted: deleted,
         isFullSync: isFullSync,
       );

  /// Returns a shallow copy of this [SyncPullResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncPullResponse copyWith({
    int? libraryVersion,
    Object? scores = _Undefined,
    Object? instrumentScores = _Undefined,
    Object? annotations = _Undefined,
    Object? setlists = _Undefined,
    Object? setlistScores = _Undefined,
    Object? deleted = _Undefined,
    bool? isFullSync,
  }) {
    return SyncPullResponse(
      libraryVersion: libraryVersion ?? this.libraryVersion,
      scores: scores is List<_i2.SyncEntityData>?
          ? scores
          : this.scores?.map((e0) => e0.copyWith()).toList(),
      instrumentScores: instrumentScores is List<_i2.SyncEntityData>?
          ? instrumentScores
          : this.instrumentScores?.map((e0) => e0.copyWith()).toList(),
      annotations: annotations is List<_i2.SyncEntityData>?
          ? annotations
          : this.annotations?.map((e0) => e0.copyWith()).toList(),
      setlists: setlists is List<_i2.SyncEntityData>?
          ? setlists
          : this.setlists?.map((e0) => e0.copyWith()).toList(),
      setlistScores: setlistScores is List<_i2.SyncEntityData>?
          ? setlistScores
          : this.setlistScores?.map((e0) => e0.copyWith()).toList(),
      deleted: deleted is List<String>?
          ? deleted
          : this.deleted?.map((e0) => e0).toList(),
      isFullSync: isFullSync ?? this.isFullSync,
    );
  }
}
