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
import '../score.dart' as _i2;
import 'package:musheet_client/src/protocol/protocol.dart' as _i3;

abstract class ScoreSyncResult implements _i1.SerializableModel {
  ScoreSyncResult._({
    required this.status,
    this.serverVersion,
    this.conflictData,
  });

  factory ScoreSyncResult({
    required String status,
    _i2.Score? serverVersion,
    _i2.Score? conflictData,
  }) = _ScoreSyncResultImpl;

  factory ScoreSyncResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return ScoreSyncResult(
      status: jsonSerialization['status'] as String,
      serverVersion: jsonSerialization['serverVersion'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.Score>(
              jsonSerialization['serverVersion'],
            ),
      conflictData: jsonSerialization['conflictData'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.Score>(
              jsonSerialization['conflictData'],
            ),
    );
  }

  String status;

  _i2.Score? serverVersion;

  _i2.Score? conflictData;

  /// Returns a shallow copy of this [ScoreSyncResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ScoreSyncResult copyWith({
    String? status,
    _i2.Score? serverVersion,
    _i2.Score? conflictData,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ScoreSyncResult',
      'status': status,
      if (serverVersion != null) 'serverVersion': serverVersion?.toJson(),
      if (conflictData != null) 'conflictData': conflictData?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ScoreSyncResultImpl extends ScoreSyncResult {
  _ScoreSyncResultImpl({
    required String status,
    _i2.Score? serverVersion,
    _i2.Score? conflictData,
  }) : super._(
         status: status,
         serverVersion: serverVersion,
         conflictData: conflictData,
       );

  /// Returns a shallow copy of this [ScoreSyncResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ScoreSyncResult copyWith({
    String? status,
    Object? serverVersion = _Undefined,
    Object? conflictData = _Undefined,
  }) {
    return ScoreSyncResult(
      status: status ?? this.status,
      serverVersion: serverVersion is _i2.Score?
          ? serverVersion
          : this.serverVersion?.copyWith(),
      conflictData: conflictData is _i2.Score?
          ? conflictData
          : this.conflictData?.copyWith(),
    );
  }
}
