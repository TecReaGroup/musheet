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

abstract class UserAppData implements _i1.SerializableModel {
  UserAppData._({
    this.id,
    required this.userId,
    required this.applicationId,
    this.preferences,
    this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserAppData({
    int? id,
    required int userId,
    required int applicationId,
    String? preferences,
    String? settings,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserAppDataImpl;

  factory UserAppData.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserAppData(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      applicationId: jsonSerialization['applicationId'] as int,
      preferences: jsonSerialization['preferences'] as String?,
      settings: jsonSerialization['settings'] as String?,
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

  int userId;

  int applicationId;

  String? preferences;

  String? settings;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [UserAppData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserAppData copyWith({
    int? id,
    int? userId,
    int? applicationId,
    String? preferences,
    String? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserAppData',
      if (id != null) 'id': id,
      'userId': userId,
      'applicationId': applicationId,
      if (preferences != null) 'preferences': preferences,
      if (settings != null) 'settings': settings,
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

class _UserAppDataImpl extends UserAppData {
  _UserAppDataImpl({
    int? id,
    required int userId,
    required int applicationId,
    String? preferences,
    String? settings,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         userId: userId,
         applicationId: applicationId,
         preferences: preferences,
         settings: settings,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [UserAppData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserAppData copyWith({
    Object? id = _Undefined,
    int? userId,
    int? applicationId,
    Object? preferences = _Undefined,
    Object? settings = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAppData(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      applicationId: applicationId ?? this.applicationId,
      preferences: preferences is String? ? preferences : this.preferences,
      settings: settings is String? ? settings : this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
