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

abstract class Setlist implements _i1.SerializableModel {
  Setlist._({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Setlist({
    int? id,
    required int userId,
    required String name,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _SetlistImpl;

  factory Setlist.fromJson(Map<String, dynamic> jsonSerialization) {
    return Setlist(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  String name;

  String? description;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  /// Returns a shallow copy of this [Setlist]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Setlist copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Setlist',
      if (id != null) 'id': id,
      'userId': userId,
      'name': name,
      if (description != null) 'description': description,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SetlistImpl extends Setlist {
  _SetlistImpl({
    int? id,
    required int userId,
    required String name,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         userId: userId,
         name: name,
         description: description,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [Setlist]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Setlist copyWith({
    Object? id = _Undefined,
    int? userId,
    String? name,
    Object? description = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return Setlist(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}
