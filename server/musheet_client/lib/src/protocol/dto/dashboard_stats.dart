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
import '../dto/team_summary.dart' as _i2;
import 'package:musheet_client/src/protocol/protocol.dart' as _i3;

abstract class DashboardStats implements _i1.SerializableModel {
  DashboardStats._({
    required this.totalTeams,
    required this.totalMembers,
    required this.activeMembers7d,
    required this.totalScores,
    required this.totalStorageUsed,
    required this.teams,
  });

  factory DashboardStats({
    required int totalTeams,
    required int totalMembers,
    required int activeMembers7d,
    required int totalScores,
    required int totalStorageUsed,
    required List<_i2.TeamSummary> teams,
  }) = _DashboardStatsImpl;

  factory DashboardStats.fromJson(Map<String, dynamic> jsonSerialization) {
    return DashboardStats(
      totalTeams: jsonSerialization['totalTeams'] as int,
      totalMembers: jsonSerialization['totalMembers'] as int,
      activeMembers7d: jsonSerialization['activeMembers7d'] as int,
      totalScores: jsonSerialization['totalScores'] as int,
      totalStorageUsed: jsonSerialization['totalStorageUsed'] as int,
      teams: _i3.Protocol().deserialize<List<_i2.TeamSummary>>(
        jsonSerialization['teams'],
      ),
    );
  }

  int totalTeams;

  int totalMembers;

  int activeMembers7d;

  int totalScores;

  int totalStorageUsed;

  List<_i2.TeamSummary> teams;

  /// Returns a shallow copy of this [DashboardStats]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DashboardStats copyWith({
    int? totalTeams,
    int? totalMembers,
    int? activeMembers7d,
    int? totalScores,
    int? totalStorageUsed,
    List<_i2.TeamSummary>? teams,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DashboardStats',
      'totalTeams': totalTeams,
      'totalMembers': totalMembers,
      'activeMembers7d': activeMembers7d,
      'totalScores': totalScores,
      'totalStorageUsed': totalStorageUsed,
      'teams': teams.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DashboardStatsImpl extends DashboardStats {
  _DashboardStatsImpl({
    required int totalTeams,
    required int totalMembers,
    required int activeMembers7d,
    required int totalScores,
    required int totalStorageUsed,
    required List<_i2.TeamSummary> teams,
  }) : super._(
         totalTeams: totalTeams,
         totalMembers: totalMembers,
         activeMembers7d: activeMembers7d,
         totalScores: totalScores,
         totalStorageUsed: totalStorageUsed,
         teams: teams,
       );

  /// Returns a shallow copy of this [DashboardStats]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DashboardStats copyWith({
    int? totalTeams,
    int? totalMembers,
    int? activeMembers7d,
    int? totalScores,
    int? totalStorageUsed,
    List<_i2.TeamSummary>? teams,
  }) {
    return DashboardStats(
      totalTeams: totalTeams ?? this.totalTeams,
      totalMembers: totalMembers ?? this.totalMembers,
      activeMembers7d: activeMembers7d ?? this.activeMembers7d,
      totalScores: totalScores ?? this.totalScores,
      totalStorageUsed: totalStorageUsed ?? this.totalStorageUsed,
      teams: teams ?? this.teams.map((e0) => e0.copyWith()).toList(),
    );
  }
}
