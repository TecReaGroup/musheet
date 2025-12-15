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

abstract class FileUploadResult
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  FileUploadResult._({
    required this.success,
    this.path,
    this.errorMessage,
  });

  factory FileUploadResult({
    required bool success,
    String? path,
    String? errorMessage,
  }) = _FileUploadResultImpl;

  factory FileUploadResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return FileUploadResult(
      success: jsonSerialization['success'] as bool,
      path: jsonSerialization['path'] as String?,
      errorMessage: jsonSerialization['errorMessage'] as String?,
    );
  }

  bool success;

  String? path;

  String? errorMessage;

  /// Returns a shallow copy of this [FileUploadResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FileUploadResult copyWith({
    bool? success,
    String? path,
    String? errorMessage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FileUploadResult',
      'success': success,
      if (path != null) 'path': path,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FileUploadResult',
      'success': success,
      if (path != null) 'path': path,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FileUploadResultImpl extends FileUploadResult {
  _FileUploadResultImpl({
    required bool success,
    String? path,
    String? errorMessage,
  }) : super._(
         success: success,
         path: path,
         errorMessage: errorMessage,
       );

  /// Returns a shallow copy of this [FileUploadResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FileUploadResult copyWith({
    bool? success,
    Object? path = _Undefined,
    Object? errorMessage = _Undefined,
  }) {
    return FileUploadResult(
      success: success ?? this.success,
      path: path is String? ? path : this.path,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
    );
  }
}
