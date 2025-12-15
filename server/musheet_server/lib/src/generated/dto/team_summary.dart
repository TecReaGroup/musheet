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

abstract class TeamSummary
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  TeamSummary._({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.sharedScores,
  });

  factory TeamSummary({
    required int id,
    required String name,
    required int memberCount,
    required int sharedScores,
  }) = _TeamSummaryImpl;

  factory TeamSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return TeamSummary(
      id: jsonSerialization['id'] as int,
      name: jsonSerialization['name'] as String,
      memberCount: jsonSerialization['memberCount'] as int,
      sharedScores: jsonSerialization['sharedScores'] as int,
    );
  }

  int id;

  String name;

  int memberCount;

  int sharedScores;

  /// Returns a shallow copy of this [TeamSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamSummary copyWith({
    int? id,
    String? name,
    int? memberCount,
    int? sharedScores,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamSummary',
      'id': id,
      'name': name,
      'memberCount': memberCount,
      'sharedScores': sharedScores,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TeamSummary',
      'id': id,
      'name': name,
      'memberCount': memberCount,
      'sharedScores': sharedScores,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TeamSummaryImpl extends TeamSummary {
  _TeamSummaryImpl({
    required int id,
    required String name,
    required int memberCount,
    required int sharedScores,
  }) : super._(
         id: id,
         name: name,
         memberCount: memberCount,
         sharedScores: sharedScores,
       );

  /// Returns a shallow copy of this [TeamSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamSummary copyWith({
    int? id,
    String? name,
    int? memberCount,
    int? sharedScores,
  }) {
    return TeamSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      memberCount: memberCount ?? this.memberCount,
      sharedScores: sharedScores ?? this.sharedScores,
    );
  }
}
