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

abstract class Application implements _i1.SerializableModel {
  Application._({
    this.id,
    required this.appId,
    required this.name,
    this.description,
    this.iconPath,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Application({
    int? id,
    required String appId,
    required String name,
    String? description,
    String? iconPath,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ApplicationImpl;

  factory Application.fromJson(Map<String, dynamic> jsonSerialization) {
    return Application(
      id: jsonSerialization['id'] as int?,
      appId: jsonSerialization['appId'] as String,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      iconPath: jsonSerialization['iconPath'] as String?,
      isActive: jsonSerialization['isActive'] as bool,
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

  String appId;

  String name;

  String? description;

  String? iconPath;

  bool isActive;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Application]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Application copyWith({
    int? id,
    String? appId,
    String? name,
    String? description,
    String? iconPath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Application',
      if (id != null) 'id': id,
      'appId': appId,
      'name': name,
      if (description != null) 'description': description,
      if (iconPath != null) 'iconPath': iconPath,
      'isActive': isActive,
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

class _ApplicationImpl extends Application {
  _ApplicationImpl({
    int? id,
    required String appId,
    required String name,
    String? description,
    String? iconPath,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         appId: appId,
         name: name,
         description: description,
         iconPath: iconPath,
         isActive: isActive,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Application]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Application copyWith({
    Object? id = _Undefined,
    String? appId,
    String? name,
    Object? description = _Undefined,
    Object? iconPath = _Undefined,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Application(
      id: id is int? ? id : this.id,
      appId: appId ?? this.appId,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      iconPath: iconPath is String? ? iconPath : this.iconPath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
