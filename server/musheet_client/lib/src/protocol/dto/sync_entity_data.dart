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

/// Sync Entity Data DTO
/// Represents entity data in a pull response
abstract class SyncEntityData implements _i1.SerializableModel {
  SyncEntityData._({
    required this.entityType,
    required this.serverId,
    required this.version,
    required this.data,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory SyncEntityData({
    required String entityType,
    required int serverId,
    required int version,
    required String data,
    required DateTime updatedAt,
    required bool isDeleted,
  }) = _SyncEntityDataImpl;

  factory SyncEntityData.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncEntityData(
      entityType: jsonSerialization['entityType'] as String,
      serverId: jsonSerialization['serverId'] as int,
      version: jsonSerialization['version'] as int,
      data: jsonSerialization['data'] as String,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      isDeleted: jsonSerialization['isDeleted'] as bool,
    );
  }

  /// Entity type
  String entityType;

  /// Server ID
  int serverId;

  /// Version when this entity was modified (= libraryVersion at modification time)
  int version;

  /// JSON-encoded entity data
  String data;

  /// When this was last updated on server
  DateTime updatedAt;

  /// If this entity is deleted (soft delete)
  bool isDeleted;

  /// Returns a shallow copy of this [SyncEntityData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncEntityData copyWith({
    String? entityType,
    int? serverId,
    int? version,
    String? data,
    DateTime? updatedAt,
    bool? isDeleted,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncEntityData',
      'entityType': entityType,
      'serverId': serverId,
      'version': version,
      'data': data,
      'updatedAt': updatedAt.toJson(),
      'isDeleted': isDeleted,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SyncEntityDataImpl extends SyncEntityData {
  _SyncEntityDataImpl({
    required String entityType,
    required int serverId,
    required int version,
    required String data,
    required DateTime updatedAt,
    required bool isDeleted,
  }) : super._(
         entityType: entityType,
         serverId: serverId,
         version: version,
         data: data,
         updatedAt: updatedAt,
         isDeleted: isDeleted,
       );

  /// Returns a shallow copy of this [SyncEntityData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncEntityData copyWith({
    String? entityType,
    int? serverId,
    int? version,
    String? data,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return SyncEntityData(
      entityType: entityType ?? this.entityType,
      serverId: serverId ?? this.serverId,
      version: version ?? this.version,
      data: data ?? this.data,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
