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
import 'package:musheet_client/src/protocol/protocol.dart' as _i2;

/// Sync Push Response DTO
/// Response from push operation
abstract class SyncPushResponse implements _i1.SerializableModel {
  SyncPushResponse._({
    required this.success,
    this.newLibraryVersion,
    this.accepted,
    this.serverIdMapping,
    required this.conflict,
    this.serverLibraryVersion,
    this.errorMessage,
  });

  factory SyncPushResponse({
    required bool success,
    int? newLibraryVersion,
    List<String>? accepted,
    Map<String, int>? serverIdMapping,
    required bool conflict,
    int? serverLibraryVersion,
    String? errorMessage,
  }) = _SyncPushResponseImpl;

  factory SyncPushResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncPushResponse(
      success: jsonSerialization['success'] as bool,
      newLibraryVersion: jsonSerialization['newLibraryVersion'] as int?,
      accepted: jsonSerialization['accepted'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['accepted'],
            ),
      serverIdMapping: jsonSerialization['serverIdMapping'] == null
          ? null
          : _i2.Protocol().deserialize<Map<String, int>>(
              jsonSerialization['serverIdMapping'],
            ),
      conflict: jsonSerialization['conflict'] as bool,
      serverLibraryVersion: jsonSerialization['serverLibraryVersion'] as int?,
      errorMessage: jsonSerialization['errorMessage'] as String?,
    );
  }

  /// Whether the push was successful
  bool success;

  /// New library version after push (if successful)
  int? newLibraryVersion;

  /// List of accepted entity IDs
  List<String>? accepted;

  /// Map of local entity ID to server ID for newly created entities
  Map<String, int>? serverIdMapping;

  /// Whether a conflict occurred (HTTP 412 equivalent)
  bool conflict;

  /// Current server library version (if conflict)
  int? serverLibraryVersion;

  /// Error message if any
  String? errorMessage;

  /// Returns a shallow copy of this [SyncPushResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncPushResponse copyWith({
    bool? success,
    int? newLibraryVersion,
    List<String>? accepted,
    Map<String, int>? serverIdMapping,
    bool? conflict,
    int? serverLibraryVersion,
    String? errorMessage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncPushResponse',
      'success': success,
      if (newLibraryVersion != null) 'newLibraryVersion': newLibraryVersion,
      if (accepted != null) 'accepted': accepted?.toJson(),
      if (serverIdMapping != null) 'serverIdMapping': serverIdMapping?.toJson(),
      'conflict': conflict,
      if (serverLibraryVersion != null)
        'serverLibraryVersion': serverLibraryVersion,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SyncPushResponseImpl extends SyncPushResponse {
  _SyncPushResponseImpl({
    required bool success,
    int? newLibraryVersion,
    List<String>? accepted,
    Map<String, int>? serverIdMapping,
    required bool conflict,
    int? serverLibraryVersion,
    String? errorMessage,
  }) : super._(
         success: success,
         newLibraryVersion: newLibraryVersion,
         accepted: accepted,
         serverIdMapping: serverIdMapping,
         conflict: conflict,
         serverLibraryVersion: serverLibraryVersion,
         errorMessage: errorMessage,
       );

  /// Returns a shallow copy of this [SyncPushResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncPushResponse copyWith({
    bool? success,
    Object? newLibraryVersion = _Undefined,
    Object? accepted = _Undefined,
    Object? serverIdMapping = _Undefined,
    bool? conflict,
    Object? serverLibraryVersion = _Undefined,
    Object? errorMessage = _Undefined,
  }) {
    return SyncPushResponse(
      success: success ?? this.success,
      newLibraryVersion: newLibraryVersion is int?
          ? newLibraryVersion
          : this.newLibraryVersion,
      accepted: accepted is List<String>?
          ? accepted
          : this.accepted?.map((e0) => e0).toList(),
      serverIdMapping: serverIdMapping is Map<String, int>?
          ? serverIdMapping
          : this.serverIdMapping?.map(
              (
                key0,
                value0,
              ) => MapEntry(
                key0,
                value0,
              ),
            ),
      conflict: conflict ?? this.conflict,
      serverLibraryVersion: serverLibraryVersion is int?
          ? serverLibraryVersion
          : this.serverLibraryVersion,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
    );
  }
}
