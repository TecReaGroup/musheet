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
import '../team.dart' as _i2;
import 'package:musheet_server/src/generated/protocol.dart' as _i3;

abstract class TeamWithRole
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  TeamWithRole._({
    required this.team,
    required this.role,
  });

  factory TeamWithRole({
    required _i2.Team team,
    required String role,
  }) = _TeamWithRoleImpl;

  factory TeamWithRole.fromJson(Map<String, dynamic> jsonSerialization) {
    return TeamWithRole(
      team: _i3.Protocol().deserialize<_i2.Team>(jsonSerialization['team']),
      role: jsonSerialization['role'] as String,
    );
  }

  _i2.Team team;

  String role;

  /// Returns a shallow copy of this [TeamWithRole]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamWithRole copyWith({
    _i2.Team? team,
    String? role,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamWithRole',
      'team': team.toJson(),
      'role': role,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TeamWithRole',
      'team': team.toJsonForProtocol(),
      'role': role,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TeamWithRoleImpl extends TeamWithRole {
  _TeamWithRoleImpl({
    required _i2.Team team,
    required String role,
  }) : super._(
         team: team,
         role: role,
       );

  /// Returns a shallow copy of this [TeamWithRole]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamWithRole copyWith({
    _i2.Team? team,
    String? role,
  }) {
    return TeamWithRole(
      team: team ?? this.team.copyWith(),
      role: role ?? this.role,
    );
  }
}
