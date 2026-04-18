import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/admin_widgets.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final index = (bytes.bitLength - 1) ~/ 10;
    final value = bytes / (1 << (index * 10));
    return '${value.toStringAsFixed(value >= 100 ? 0 : value >= 10 ? 1 : 2)} ${suffixes[index]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      loading: () => const Center(
        child: AdminLoadingIndicator(message: 'Loading dashboard overview...'),
      ),
      error: (error, _) => Center(
        child: AdminEmptyState(
          icon: LucideIcons.circleAlert,
          title: 'Failed to load dashboard',
          subtitle: error.toString(),
          action: ElevatedButton.icon(
            onPressed: () => ref.invalidate(dashboardStatsProvider),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text('Retry'),
          ),
        ),
      ),
      data: (stats) {
        if (stats == null) {
          return const Center(
            child: AdminEmptyState(
              icon: LucideIcons.layoutDashboard,
              title: 'No dashboard data available',
              subtitle: 'Authenticate again or wait for data synchronization.',
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardStatsProvider),
          child: AdminPageScaffold(
            eyebrow: 'Overview',
            title: 'Admin dashboard',
            subtitle:
                'A unified operational view for users, teams, content, and storage across the MuSheet platform.',
            actions: [
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(dashboardStatsProvider),
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: const Text('Refresh data'),
              ),
            ],
            hero: AdminInfoHero(
              icon: LucideIcons.sparkles,
              title: 'Platform health snapshot',
              subtitle:
                  'Use this page as the top-level operating center. The layout and spacing now follow the same brighter product language used by the app side.',
              trailing: [
                AdminMetricPill(
                  icon: LucideIcons.hardDrive,
                  label: 'Storage',
                  value: _formatBytes(stats.totalStorageUsed),
                  accent: AppColors.teal500,
                ),
                AdminMetricPill(
                  icon: LucideIcons.users,
                  label: 'Members',
                  value: '${stats.totalMembers}',
                ),
                AdminMetricPill(
                  icon: LucideIcons.usersRound,
                  label: 'Teams',
                  value: '${stats.totalTeams}',
                  accent: AppColors.purple600,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminKpiGrid(
                  children: [
                    AdminStatCard.users(count: stats.totalMembers),
                    AdminStatCard.activeUsers(count: stats.activeMembers7d),
                    AdminStatCard.teams(count: stats.totalTeams),
                    AdminStatCard.scores(count: stats.totalScores),
                  ],
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 1080) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _TeamActivityCard(teams: stats.teams),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: _StorageCard(totalStorage: stats.totalStorageUsed),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _TeamActivityCard(teams: stats.teams),
                        const SizedBox(height: 24),
                        _StorageCard(totalStorage: stats.totalStorageUsed),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                DataTableCard(
                  title: 'Team overview',
                  subtitle: 'Membership and shared score distribution by team.',
                  icon: LucideIcons.table2,
                  child: AdminResponsiveDataTable(
                    minWidth: 760,
                    emptyHint: 'No teams have been created yet.',
                    columns: const [
                      DataColumn(label: Text('Team')),
                      DataColumn(label: Text('Members')),
                      DataColumn(label: Text('Shared Scores')),
                    ],
                    rows: stats.teams.map((team) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              team.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataCell(
                            StatusBadge.count(
                              count: team.memberCount,
                              icon: LucideIcons.users,
                              color: AppColors.blue600,
                            ),
                          ),
                          DataCell(
                            StatusBadge.count(
                              count: team.sharedScores,
                              icon: LucideIcons.music4,
                              color: AppColors.emerald600,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TeamActivityCard extends StatelessWidget {
  final List<dynamic> teams;

  const _TeamActivityCard({required this.teams});

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Team activity',
      subtitle: 'Compare team size with shared score volume.',
      icon: LucideIcons.chartColumn,
      contentPadding: EdgeInsets.zero,
      child: teams.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: AdminEmptyState(
                icon: LucideIcons.usersRound,
                title: 'No teams yet',
                subtitle: 'Create a team to start tracking collaborative activity.',
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: SizedBox(
                height: 320,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _maxY,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: _interval,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: AppColors.gray200,
                        strokeWidth: 1,
                      ),
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.gray900,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final team = teams[group.x.toInt()];
                          final label = rodIndex == 0 ? 'Members' : 'Scores';
                          return BarTooltipItem(
                            '${team.name}\n$label: ${rod.toY.toInt()}',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: AppColors.gray500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= teams.length) {
                              return const SizedBox.shrink();
                            }
                            final name = teams[index].name as String;
                            final short = name.length > 10 ? '${name.substring(0, 10)}…' : name;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                short,
                                style: const TextStyle(
                                  color: AppColors.gray500,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < teams.length; i++)
                        BarChartGroupData(
                          x: i,
                          barsSpace: 6,
                          barRods: [
                            BarChartRodData(
                              toY: teams[i].memberCount.toDouble(),
                              color: AppColors.blue600,
                              width: 14,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            BarChartRodData(
                              toY: teams[i].sharedScores.toDouble(),
                              color: AppColors.emerald600,
                              width: 14,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  double get _maxY {
    if (teams.isEmpty) return 10;
    var maxValue = 0;
    for (final team in teams) {
      final value = [team.memberCount as int, team.sharedScores as int]
          .reduce((a, b) => a > b ? a : b);
      if (value > maxValue) {
        maxValue = value;
      }
    }
    return (maxValue + 4).toDouble();
  }

  double get _interval {
    final maxValue = _maxY;
    if (maxValue <= 10) return 2;
    if (maxValue <= 30) return 5;
    if (maxValue <= 60) return 10;
    return 20;
  }
}

class _StorageCard extends StatelessWidget {
  final int totalStorage;

  const _StorageCard({required this.totalStorage});

  @override
  Widget build(BuildContext context) {
    final userStorage = (totalStorage * 0.7).round();
    final teamStorage = totalStorage - userStorage;

    return AdminSectionCard(
      title: 'Storage distribution',
      subtitle: 'Approximate split between personal and team-owned assets.',
      icon: LucideIcons.chartPie,
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: totalStorage <= 0
                ? const Center(
                    child: Text(
                      'No storage consumed yet',
                      style: TextStyle(color: AppColors.gray500),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      centerSpaceRadius: 52,
                      sectionsSpace: 4,
                      sections: [
                        PieChartSectionData(
                          color: AppColors.blue600,
                          value: userStorage.toDouble(),
                          title: '',
                          radius: 40,
                        ),
                        PieChartSectionData(
                          color: AppColors.emerald600,
                          value: teamStorage.toDouble(),
                          title: '',
                          radius: 40,
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                color: AppColors.blue600,
                label: 'User assets',
                value: '$userStorage B',
              ),
              const SizedBox(width: 16),
              _LegendDot(
                color: AppColors.emerald600,
                label: 'Team assets',
                value: '$teamStorage B',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label · $value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gray700,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
