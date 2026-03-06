import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/admin_widgets.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (bytes == 0) ? 0 : (bytes.bitLength - 1) ~/ 10;
    final value = bytes / (1 << (i * 10));
    return '${value.toStringAsFixed(value >= 100 ? 0 : value >= 10 ? 1 : 2)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.slate900,
      body: statsAsync.when(
        loading: () =>
            const AdminLoadingIndicator(message: 'Loading dashboard...'),
        error: (error, _) => AdminEmptyState(
          icon: LucideIcons.circleAlert,
          title: 'Failed to load dashboard',
          subtitle: error.toString(),
          action: ElevatedButton.icon(
            onPressed: () => ref.invalidate(dashboardStatsProvider),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Retry'),
          ),
        ),
        data: (stats) {
          if (stats == null) {
            return const AdminEmptyState(
              icon: LucideIcons.layoutDashboard,
              title: 'No data available',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardStatsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Overview of your MuSheet system',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.invalidate(dashboardStatsProvider),
                        icon: Icon(LucideIcons.refreshCw,
                            color: AppColors.gray400),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 1200
                          ? 5
                          : constraints.maxWidth > 800
                              ? 3
                              : constraints.maxWidth > 500
                                  ? 2
                                  : 1;

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          AdminStatCard.users(count: stats.totalMembers),
                          AdminStatCard.activeUsers(count: stats.activeMembers7d),
                          AdminStatCard.teams(count: stats.totalTeams),
                          AdminStatCard.scores(count: stats.totalScores),
                          AdminStatCard.storage(
                            size: _formatBytes(stats.totalStorageUsed),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Charts Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 900) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _TeamActivityChart(teams: stats.teams),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _StorageDistributionChart(
                                totalStorage: stats.totalStorageUsed,
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _TeamActivityChart(teams: stats.teams),
                          const SizedBox(height: 24),
                          _StorageDistributionChart(
                            totalStorage: stats.totalStorageUsed,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Teams Overview Table
                  DataTableCard(
                    title: 'Teams Overview',
                    icon: LucideIcons.users,
                    child: _TeamsOverviewTable(teams: stats.teams),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// Team Activity Chart
// ============================================================================

class _TeamActivityChart extends StatelessWidget {
  final List<dynamic> teams;

  const _TeamActivityChart({required this.teams});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.chartBar, size: 20, color: AppColors.gray400),
              const SizedBox(width: 10),
              const Text(
                'Team Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (teams.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No teams yet',
                  style: TextStyle(color: AppColors.gray500),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.slate700,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final team = teams[group.x.toInt()];
                        final label = rodIndex == 0 ? 'Members' : 'Scores';
                        return BarTooltipItem(
                          '${team.name}\n$label: ${rod.toY.toInt()}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= teams.length) {
                            return const SizedBox.shrink();
                          }
                          final team = teams[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _truncate(team.name, 8),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.gray500,
                              ),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.gray500,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getInterval(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.slate700,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarGroups(),
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: AppColors.indigo500, label: 'Members'),
              const SizedBox(width: 24),
              _LegendItem(color: AppColors.emerald500, label: 'Scores'),
            ],
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    double max = 10;
    for (final team in teams) {
      if (team.memberCount > max) max = team.memberCount.toDouble();
      if (team.sharedScores > max) max = team.sharedScores.toDouble();
    }
    return max * 1.2;
  }

  double _getInterval() {
    final maxY = _getMaxY();
    if (maxY <= 10) return 2;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    return 50;
  }

  List<BarChartGroupData> _buildBarGroups() {
    return teams.take(6).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final team = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: team.memberCount.toDouble(),
            color: AppColors.indigo500,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: team.sharedScores.toDouble(),
            color: AppColors.emerald500,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    }).toList();
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 1)}…';
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.gray400,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Storage Distribution Chart
// ============================================================================

class _StorageDistributionChart extends StatelessWidget {
  final int totalStorage;

  const _StorageDistributionChart({required this.totalStorage});

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (bytes == 0) ? 0 : (bytes.bitLength - 1) ~/ 10;
    final value = bytes / (1 << (i * 10));
    return '${value.toStringAsFixed(value >= 100 ? 0 : value >= 10 ? 1 : 2)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    // Mock distribution - in real app, get from API
    final userStorage = (totalStorage * 0.6).toInt();
    final teamStorage = (totalStorage * 0.4).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.chartPie, size: 20, color: AppColors.gray400),
              const SizedBox(width: 10),
              const Text(
                'Storage Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (totalStorage == 0)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No storage used',
                  style: TextStyle(color: AppColors.gray500),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: AppColors.indigo500,
                      value: userStorage.toDouble(),
                      title: '',
                      radius: 50,
                    ),
                    PieChartSectionData(
                      color: AppColors.purple500,
                      value: teamStorage.toDouble(),
                      title: '',
                      radius: 50,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Legend
          _StorageLegendItem(
            color: AppColors.indigo500,
            label: 'User Storage',
            value: _formatBytes(userStorage),
          ),
          const SizedBox(height: 8),
          _StorageLegendItem(
            color: AppColors.purple500,
            label: 'Team Storage',
            value: _formatBytes(teamStorage),
          ),
        ],
      ),
    );
  }
}

class _StorageLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _StorageLegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.gray400,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.gray200,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Teams Overview Table
// ============================================================================

class _TeamsOverviewTable extends StatelessWidget {
  final List<dynamic> teams;

  const _TeamsOverviewTable({required this.teams});

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Text(
            'No teams yet',
            style: TextStyle(color: AppColors.gray500),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Team Name')),
          DataColumn(label: Text('Members'), numeric: true),
          DataColumn(label: Text('Shared Scores'), numeric: true),
        ],
        rows: teams.map((team) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  team.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              DataCell(
                StatusBadge.count(
                  count: team.memberCount,
                  icon: LucideIcons.users,
                  color: AppColors.indigo500,
                ),
              ),
              DataCell(
                StatusBadge.count(
                  count: team.sharedScores,
                  icon: LucideIcons.music,
                  color: AppColors.emerald500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
