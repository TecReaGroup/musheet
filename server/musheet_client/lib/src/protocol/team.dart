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

abstract class Team implements _i1.SerializableModel {
  Team._({
    this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team({
    int? id,
    required String name,
    String? description,
    required String inviteCode,
    required int createdById,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TeamImpl;

  factory Team.fromJson(Map<String, dynamic> jsonSerialization) {
    return Team(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      inviteCode: jsonSerialization['inviteCode'] as String,
      createdById: jsonSerialization['createdById'] as int,
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

  String name;

  String? description;

  String inviteCode;

  int createdById;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Team]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Team copyWith({
    int? id,
    String? name,
    String? description,
    String? inviteCode,
    int? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Team',
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'inviteCode': inviteCode,
      'createdById': createdById,
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

class _TeamImpl extends Team {
  _TeamImpl({
    int? id,
    required String name,
    String? description,
    required String inviteCode,
    required int createdById,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         name: name,
         description: description,
         inviteCode: inviteCode,
         createdById: createdById,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Team]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Team copyWith({
    Object? id = _Undefined,
    String? name,
    Object? description = _Undefined,
    String? inviteCode,
    int? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      inviteCode: inviteCode ?? this.inviteCode,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
