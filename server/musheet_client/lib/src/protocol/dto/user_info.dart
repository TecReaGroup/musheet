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

abstract class UserInfo implements _i1.SerializableModel {
  UserInfo._({
    required this.id,
    required this.username,
    this.displayName,
    required this.isAdmin,
    required this.isDisabled,
    required this.createdAt,
  });

  factory UserInfo({
    required int id,
    required String username,
    String? displayName,
    required bool isAdmin,
    required bool isDisabled,
    required DateTime createdAt,
  }) = _UserInfoImpl;

  factory UserInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserInfo(
      id: jsonSerialization['id'] as int,
      username: jsonSerialization['username'] as String,
      displayName: jsonSerialization['displayName'] as String?,
      isAdmin: jsonSerialization['isAdmin'] as bool,
      isDisabled: jsonSerialization['isDisabled'] as bool,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int id;

  String username;

  String? displayName;

  bool isAdmin;

  bool isDisabled;

  DateTime createdAt;

  /// Returns a shallow copy of this [UserInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserInfo copyWith({
    int? id,
    String? username,
    String? displayName,
    bool? isAdmin,
    bool? isDisabled,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserInfo',
      'id': id,
      'username': username,
      if (displayName != null) 'displayName': displayName,
      'isAdmin': isAdmin,
      'isDisabled': isDisabled,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserInfoImpl extends UserInfo {
  _UserInfoImpl({
    required int id,
    required String username,
    String? displayName,
    required bool isAdmin,
    required bool isDisabled,
    required DateTime createdAt,
  }) : super._(
         id: id,
         username: username,
         displayName: displayName,
         isAdmin: isAdmin,
         isDisabled: isDisabled,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [UserInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserInfo copyWith({
    int? id,
    String? username,
    Object? displayName = _Undefined,
    bool? isAdmin,
    bool? isDisabled,
    DateTime? createdAt,
  }) {
    return UserInfo(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName is String? ? displayName : this.displayName,
      isAdmin: isAdmin ?? this.isAdmin,
      isDisabled: isDisabled ?? this.isDisabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
