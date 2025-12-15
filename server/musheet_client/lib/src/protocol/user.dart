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

abstract class User implements _i1.SerializableModel {
  User._({
    this.id,
    required this.username,
    required this.passwordHash,
    this.displayName,
    this.avatarPath,
    this.bio,
    this.preferredInstrument,
    required this.isAdmin,
    required this.isDisabled,
    required this.mustChangePassword,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User({
    int? id,
    required String username,
    required String passwordHash,
    String? displayName,
    String? avatarPath,
    String? bio,
    String? preferredInstrument,
    required bool isAdmin,
    required bool isDisabled,
    required bool mustChangePassword,
    DateTime? lastLoginAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserImpl;

  factory User.fromJson(Map<String, dynamic> jsonSerialization) {
    return User(
      id: jsonSerialization['id'] as int?,
      username: jsonSerialization['username'] as String,
      passwordHash: jsonSerialization['passwordHash'] as String,
      displayName: jsonSerialization['displayName'] as String?,
      avatarPath: jsonSerialization['avatarPath'] as String?,
      bio: jsonSerialization['bio'] as String?,
      preferredInstrument: jsonSerialization['preferredInstrument'] as String?,
      isAdmin: jsonSerialization['isAdmin'] as bool,
      isDisabled: jsonSerialization['isDisabled'] as bool,
      mustChangePassword: jsonSerialization['mustChangePassword'] as bool,
      lastLoginAt: jsonSerialization['lastLoginAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastLoginAt'],
            ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String username;

  String passwordHash;

  String? displayName;

  String? avatarPath;

  String? bio;

  String? preferredInstrument;

  bool isAdmin;

  bool isDisabled;

  bool mustChangePassword;

  DateTime? lastLoginAt;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [User]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  User copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? displayName,
    String? avatarPath,
    String? bio,
    String? preferredInstrument,
    bool? isAdmin,
    bool? isDisabled,
    bool? mustChangePassword,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'User',
      if (id != null) 'id': id,
      'username': username,
      'passwordHash': passwordHash,
      if (displayName != null) 'displayName': displayName,
      if (avatarPath != null) 'avatarPath': avatarPath,
      if (bio != null) 'bio': bio,
      if (preferredInstrument != null)
        'preferredInstrument': preferredInstrument,
      'isAdmin': isAdmin,
      'isDisabled': isDisabled,
      'mustChangePassword': mustChangePassword,
      if (lastLoginAt != null) 'lastLoginAt': lastLoginAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserImpl extends User {
  _UserImpl({
    int? id,
    required String username,
    required String passwordHash,
    String? displayName,
    String? avatarPath,
    String? bio,
    String? preferredInstrument,
    required bool isAdmin,
    required bool isDisabled,
    required bool mustChangePassword,
    DateTime? lastLoginAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         username: username,
         passwordHash: passwordHash,
         displayName: displayName,
         avatarPath: avatarPath,
         bio: bio,
         preferredInstrument: preferredInstrument,
         isAdmin: isAdmin,
         isDisabled: isDisabled,
         mustChangePassword: mustChangePassword,
         lastLoginAt: lastLoginAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [User]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  User copyWith({
    Object? id = _Undefined,
    String? username,
    String? passwordHash,
    Object? displayName = _Undefined,
    Object? avatarPath = _Undefined,
    Object? bio = _Undefined,
    Object? preferredInstrument = _Undefined,
    bool? isAdmin,
    bool? isDisabled,
    bool? mustChangePassword,
    Object? lastLoginAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id is int? ? id : this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarPath: avatarPath is String? ? avatarPath : this.avatarPath,
      bio: bio is String? ? bio : this.bio,
      preferredInstrument: preferredInstrument is String?
          ? preferredInstrument
          : this.preferredInstrument,
      isAdmin: isAdmin ?? this.isAdmin,
      isDisabled: isDisabled ?? this.isDisabled,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      lastLoginAt: lastLoginAt is DateTime? ? lastLoginAt : this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
