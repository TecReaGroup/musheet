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

abstract class UserStorage implements _i1.SerializableModel {
  UserStorage._({
    this.id,
    required this.userId,
    required this.usedBytes,
    required this.quotaBytes,
    required this.lastCalculatedAt,
  });

  factory UserStorage({
    int? id,
    required int userId,
    required int usedBytes,
    required int quotaBytes,
    required DateTime lastCalculatedAt,
  }) = _UserStorageImpl;

  factory UserStorage.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserStorage(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      usedBytes: jsonSerialization['usedBytes'] as int,
      quotaBytes: jsonSerialization['quotaBytes'] as int,
      lastCalculatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastCalculatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  int usedBytes;

  int quotaBytes;

  DateTime lastCalculatedAt;

  /// Returns a shallow copy of this [UserStorage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserStorage copyWith({
    int? id,
    int? userId,
    int? usedBytes,
    int? quotaBytes,
    DateTime? lastCalculatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserStorage',
      if (id != null) 'id': id,
      'userId': userId,
      'usedBytes': usedBytes,
      'quotaBytes': quotaBytes,
      'lastCalculatedAt': lastCalculatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserStorageImpl extends UserStorage {
  _UserStorageImpl({
    int? id,
    required int userId,
    required int usedBytes,
    required int quotaBytes,
    required DateTime lastCalculatedAt,
  }) : super._(
         id: id,
         userId: userId,
         usedBytes: usedBytes,
         quotaBytes: quotaBytes,
         lastCalculatedAt: lastCalculatedAt,
       );

  /// Returns a shallow copy of this [UserStorage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserStorage copyWith({
    Object? id = _Undefined,
    int? userId,
    int? usedBytes,
    int? quotaBytes,
    DateTime? lastCalculatedAt,
  }) {
    return UserStorage(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      usedBytes: usedBytes ?? this.usedBytes,
      quotaBytes: quotaBytes ?? this.quotaBytes,
      lastCalculatedAt: lastCalculatedAt ?? this.lastCalculatedAt,
    );
  }
}
