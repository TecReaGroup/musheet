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

abstract class AvatarUploadResult implements _i1.SerializableModel {
  AvatarUploadResult._({
    required this.success,
    this.avatarUrl,
    this.thumbnailUrl,
    this.errorMessage,
  });

  factory AvatarUploadResult({
    required bool success,
    String? avatarUrl,
    String? thumbnailUrl,
    String? errorMessage,
  }) = _AvatarUploadResultImpl;

  factory AvatarUploadResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return AvatarUploadResult(
      success: jsonSerialization['success'] as bool,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      thumbnailUrl: jsonSerialization['thumbnailUrl'] as String?,
      errorMessage: jsonSerialization['errorMessage'] as String?,
    );
  }

  bool success;

  String? avatarUrl;

  String? thumbnailUrl;

  String? errorMessage;

  /// Returns a shallow copy of this [AvatarUploadResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AvatarUploadResult copyWith({
    bool? success,
    String? avatarUrl,
    String? thumbnailUrl,
    String? errorMessage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AvatarUploadResult',
      'success': success,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AvatarUploadResultImpl extends AvatarUploadResult {
  _AvatarUploadResultImpl({
    required bool success,
    String? avatarUrl,
    String? thumbnailUrl,
    String? errorMessage,
  }) : super._(
         success: success,
         avatarUrl: avatarUrl,
         thumbnailUrl: thumbnailUrl,
         errorMessage: errorMessage,
       );

  /// Returns a shallow copy of this [AvatarUploadResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AvatarUploadResult copyWith({
    bool? success,
    Object? avatarUrl = _Undefined,
    Object? thumbnailUrl = _Undefined,
    Object? errorMessage = _Undefined,
  }) {
    return AvatarUploadResult(
      success: success ?? this.success,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      thumbnailUrl: thumbnailUrl is String? ? thumbnailUrl : this.thumbnailUrl,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
    );
  }
}
