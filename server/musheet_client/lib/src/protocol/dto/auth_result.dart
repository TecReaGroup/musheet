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
import '../user.dart' as _i2;
import 'package:musheet_client/src/protocol/protocol.dart' as _i3;

abstract class AuthResult implements _i1.SerializableModel {
  AuthResult._({
    required this.success,
    this.token,
    this.user,
    required this.mustChangePassword,
    this.errorMessage,
  });

  factory AuthResult({
    required bool success,
    String? token,
    _i2.User? user,
    required bool mustChangePassword,
    String? errorMessage,
  }) = _AuthResultImpl;

  factory AuthResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthResult(
      success: jsonSerialization['success'] as bool,
      token: jsonSerialization['token'] as String?,
      user: jsonSerialization['user'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.User>(jsonSerialization['user']),
      mustChangePassword: jsonSerialization['mustChangePassword'] as bool,
      errorMessage: jsonSerialization['errorMessage'] as String?,
    );
  }

  bool success;

  String? token;

  _i2.User? user;

  bool mustChangePassword;

  String? errorMessage;

  /// Returns a shallow copy of this [AuthResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AuthResult copyWith({
    bool? success,
    String? token,
    _i2.User? user,
    bool? mustChangePassword,
    String? errorMessage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuthResult',
      'success': success,
      if (token != null) 'token': token,
      if (user != null) 'user': user?.toJson(),
      'mustChangePassword': mustChangePassword,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuthResultImpl extends AuthResult {
  _AuthResultImpl({
    required bool success,
    String? token,
    _i2.User? user,
    required bool mustChangePassword,
    String? errorMessage,
  }) : super._(
         success: success,
         token: token,
         user: user,
         mustChangePassword: mustChangePassword,
         errorMessage: errorMessage,
       );

  /// Returns a shallow copy of this [AuthResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AuthResult copyWith({
    bool? success,
    Object? token = _Undefined,
    Object? user = _Undefined,
    bool? mustChangePassword,
    Object? errorMessage = _Undefined,
  }) {
    return AuthResult(
      success: success ?? this.success,
      token: token is String? ? token : this.token,
      user: user is _i2.User? ? user : this.user?.copyWith(),
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
    );
  }
}
