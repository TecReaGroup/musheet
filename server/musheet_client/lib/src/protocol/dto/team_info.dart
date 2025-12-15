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

abstract class TeamInfo implements _i1.SerializableModel {
  TeamInfo._({
    required this.id,
    required this.name,
    required this.role,
  });

  factory TeamInfo({
    required int id,
    required String name,
    required String role,
  }) = _TeamInfoImpl;

  factory TeamInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return TeamInfo(
      id: jsonSerialization['id'] as int,
      name: jsonSerialization['name'] as String,
      role: jsonSerialization['role'] as String,
    );
  }

  int id;

  String name;

  String role;

  /// Returns a shallow copy of this [TeamInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamInfo copyWith({
    int? id,
    String? name,
    String? role,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamInfo',
      'id': id,
      'name': name,
      'role': role,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TeamInfoImpl extends TeamInfo {
  _TeamInfoImpl({
    required int id,
    required String name,
    required String role,
  }) : super._(
         id: id,
         name: name,
         role: role,
       );

  /// Returns a shallow copy of this [TeamInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamInfo copyWith({
    int? id,
    String? name,
    String? role,
  }) {
    return TeamInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }
}
