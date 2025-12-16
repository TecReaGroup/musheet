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

/// Sync Entity Change DTO
/// Represents a single entity change in a sync request
abstract class SyncEntityChange
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SyncEntityChange._({
    required this.entityType,
    required this.entityId,
    this.serverId,
    required this.operation,
    required this.version,
    required this.data,
    required this.localUpdatedAt,
  });

  factory SyncEntityChange({
    required String entityType,
    required String entityId,
    int? serverId,
    required String operation,
    required int version,
    required String data,
    required DateTime localUpdatedAt,
  }) = _SyncEntityChangeImpl;

  factory SyncEntityChange.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncEntityChange(
      entityType: jsonSerialization['entityType'] as String,
      entityId: jsonSerialization['entityId'] as String,
      serverId: jsonSerialization['serverId'] as int?,
      operation: jsonSerialization['operation'] as String,
      version: jsonSerialization['version'] as int,
      data: jsonSerialization['data'] as String,
      localUpdatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['localUpdatedAt'],
      ),
    );
  }

  /// Entity type (score, instrumentScore, annotation, setlist, setlistScore)
  String entityType;

  /// Entity ID (client-side UUID)
  String entityId;

  /// Server ID (if known, for updates)
  int? serverId;

  /// Operation type: create, update, delete
  String operation;

  /// Version when this change was made
  int version;

  /// JSON-encoded entity data
  String data;

  /// When this change was made locally
  DateTime localUpdatedAt;

  /// Returns a shallow copy of this [SyncEntityChange]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncEntityChange copyWith({
    String? entityType,
    String? entityId,
    int? serverId,
    String? operation,
    int? version,
    String? data,
    DateTime? localUpdatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncEntityChange',
      'entityType': entityType,
      'entityId': entityId,
      if (serverId != null) 'serverId': serverId,
      'operation': operation,
      'version': version,
      'data': data,
      'localUpdatedAt': localUpdatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SyncEntityChange',
      'entityType': entityType,
      'entityId': entityId,
      if (serverId != null) 'serverId': serverId,
      'operation': operation,
      'version': version,
      'data': data,
      'localUpdatedAt': localUpdatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SyncEntityChangeImpl extends SyncEntityChange {
  _SyncEntityChangeImpl({
    required String entityType,
    required String entityId,
    int? serverId,
    required String operation,
    required int version,
    required String data,
    required DateTime localUpdatedAt,
  }) : super._(
         entityType: entityType,
         entityId: entityId,
         serverId: serverId,
         operation: operation,
         version: version,
         data: data,
         localUpdatedAt: localUpdatedAt,
       );

  /// Returns a shallow copy of this [SyncEntityChange]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncEntityChange copyWith({
    String? entityType,
    String? entityId,
    Object? serverId = _Undefined,
    String? operation,
    int? version,
    String? data,
    DateTime? localUpdatedAt,
  }) {
    return SyncEntityChange(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      serverId: serverId is int? ? serverId : this.serverId,
      operation: operation ?? this.operation,
      version: version ?? this.version,
      data: data ?? this.data,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    );
  }
}
