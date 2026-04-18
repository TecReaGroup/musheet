import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:musheet_shared_ui/musheet_shared_ui.dart';
import '../../core/admin_api_client.dart';
import '../theme/app_colors.dart';

class AdminSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool outlined;
  final Color? color;

  const AdminSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 20,
    this.outlined = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: outlined ? Border.all(color: AppColors.gray200) : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AdminPageScaffold extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget? hero;
  final Widget child;

  const AdminPageScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
    this.hero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FBFF), Color(0xFFF3F7FC)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminPageHeader(
                    eyebrow: eyebrow,
                    title: title,
                    subtitle: subtitle,
                    actions: actions,
                  ),
                  if (hero != null) ...[
                    const SizedBox(height: 24),
                    hero!,
                  ],
                  const SizedBox(height: 24),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminPageHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const AdminPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 16,
      spacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.blue600,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.gray600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (actions.isNotEmpty)
          Wrap(spacing: 12, runSpacing: 12, children: actions),
      ],
    );
  }
}

class AdminSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> actions;
  final Widget child;
  final EdgeInsetsGeometry contentPadding;

  const AdminSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.actions = const [],
    this.contentPadding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.blue50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, size: 20, color: AppColors.blue600),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (actions.isNotEmpty)
                Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ),
          const SizedBox(height: 20),
          Padding(padding: contentPadding, child: child),
        ],
      ),
    );
  }
}

class AdminInfoHero extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> trailing;

  const AdminInfoHero({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminSurface(
      padding: const EdgeInsets.all(24),
      radius: 22,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF6FF), Color(0xFFECFDF5)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.blue100),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const MuSheetBrandMark(size: 52, radius: 16),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: AppColors.blue600),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.gray900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing.isNotEmpty) ...[
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 12,
                    children: trailing,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminKpiGrid extends StatelessWidget {
  final List<Widget> children;

  const AdminKpiGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1320
            ? 4
            : width >= 900
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: width >= 900 ? 1.85 : 1.55,
          children: children,
        );
      },
    );
  }
}

class AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? helper;
  final Color accentColor;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.helper,
    this.accentColor = AppColors.blue600,
    this.onTap,
  });

  factory AdminStatCard.users({
    Key? key,
    required int count,
    VoidCallback? onTap,
  }) {
    return AdminStatCard(
      key: key,
      icon: LucideIcons.userRound,
      label: 'Total Users',
      value: '$count',
      helper: 'All registered accounts',
      accentColor: AppColors.blue600,
      onTap: onTap,
    );
  }

  factory AdminStatCard.activeUsers({
    Key? key,
    required int count,
    VoidCallback? onTap,
  }) {
    return AdminStatCard(
      key: key,
      icon: LucideIcons.userRoundCheck,
      label: 'Active Users',
      value: '$count',
      helper: 'Recent 7 day activity',
      accentColor: AppColors.emerald600,
      onTap: onTap,
    );
  }

  factory AdminStatCard.teams({
    Key? key,
    required int count,
    VoidCallback? onTap,
  }) {
    return AdminStatCard(
      key: key,
      icon: LucideIcons.users,
      label: 'Teams',
      value: '$count',
      helper: 'Collaboration spaces',
      accentColor: AppColors.purple600,
      onTap: onTap,
    );
  }

  factory AdminStatCard.scores({
    Key? key,
    required int count,
    VoidCallback? onTap,
  }) {
    return AdminStatCard(
      key: key,
      icon: LucideIcons.fileMusic,
      label: 'Scores',
      value: '$count',
      helper: 'Published music sheets',
      accentColor: AppColors.yellow600,
      onTap: onTap,
    );
  }

  factory AdminStatCard.storage({
    Key? key,
    required String size,
    VoidCallback? onTap,
  }) {
    return AdminStatCard(
      key: key,
      icon: LucideIcons.database,
      label: 'Storage Used',
      value: size,
      helper: 'Combined media footprint',
      accentColor: AppColors.teal500,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = AdminSurface(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(LucideIcons.arrowUpRight, size: 18, color: AppColors.gray400),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.gray900,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.gray800,
                ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(
              helper!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.gray500,
                  ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class AdminTableCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> actions;
  final Widget child;

  const AdminTableCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (icon != null) ...[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, size: 18, color: AppColors.gray700),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.gray500),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty)
                    Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DataTableCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final List<Widget>? actions;
  final String? subtitle;

  const DataTableCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.actions,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AdminTableCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      actions: actions ?? const [],
      child: child,
    );
  }
}

class AdminResponsiveDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double minWidth;
  final String? emptyHint;

  const AdminResponsiveDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 840,
    this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (rows.isEmpty && emptyHint != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            emptyHint!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.gray500,
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: SizedBox(
        width: double.infinity,
        child: DataTable(columns: columns, rows: rows),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.admin({Key? key}) {
    return StatusBadge(
      key: key,
      label: 'Admin',
      backgroundColor: AppColors.blue50,
      textColor: AppColors.blue600,
      icon: LucideIcons.shieldCheck,
    );
  }

  factory StatusBadge.user({Key? key}) {
    return StatusBadge(
      key: key,
      label: 'User',
      backgroundColor: AppColors.gray100,
      textColor: AppColors.gray700,
      icon: LucideIcons.user,
    );
  }

  factory StatusBadge.active({Key? key}) {
    return StatusBadge(
      key: key,
      label: 'Active',
      backgroundColor: AppColors.emerald50,
      textColor: AppColors.emerald600,
      icon: LucideIcons.badgeCheck,
    );
  }

  factory StatusBadge.disabled({Key? key}) {
    return StatusBadge(
      key: key,
      label: 'Disabled',
      backgroundColor: AppColors.red50,
      textColor: AppColors.red600,
      icon: LucideIcons.ban,
    );
  }

  factory StatusBadge.count({
    Key? key,
    required int count,
    required IconData icon,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.blue600;
    return StatusBadge(
      key: key,
      label: '$count',
      backgroundColor: effectiveColor.withValues(alpha: 0.10),
      textColor: effectiveColor,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final bool isDanger;

  const ActionIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? (isDanger ? AppColors.red600 : AppColors.gray700);

    return Tooltip(
      message: tooltip ?? '',
      child: IconButton.filledTonal(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor:
              isDanger ? AppColors.red50 : AppColors.gray100,
          foregroundColor: effectiveColor,
          disabledBackgroundColor: AppColors.gray100,
          disabledForegroundColor: AppColors.gray400,
        ),
        icon: Icon(icon, size: 18),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: AdminSurface(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, size: 32, color: AppColors.gray600),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.gray900,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray500,
                    height: 1.5,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AdminLoadingIndicator extends StatelessWidget {
  final String? message;

  const AdminLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return MuSheetLoadingIndicator(message: message);
  }
}

class AdminInlineMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final Color backgroundColor;

  const AdminInlineMessage({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const AdminMetricPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppColors.blue600,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gray500,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.gray900,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDanger;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.isDanger = false,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        isDanger: isDanger,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDanger ? AppColors.red500 : AppColors.blue600,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.hasMore,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Text(
            'Page ${currentPage + 1}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray600,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: !isLoading && currentPage > 0 ? onPrevious : null,
            icon: const Icon(LucideIcons.chevronLeft, size: 18),
            label: const Text('Previous'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: !isLoading && hasMore ? onNext : null,
            icon: const Icon(LucideIcons.chevronRight, size: 18),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class AdminUserAvatar extends StatefulWidget {
  final String? name;
  final int? userId;
  final double size;

  const AdminUserAvatar({
    super.key,
    this.name,
    this.userId,
    this.size = 40,
  });

  @override
  State<AdminUserAvatar> createState() => _AdminUserAvatarState();
}

class _AdminUserAvatarState extends State<AdminUserAvatar> {
  Uint8List? _avatarBytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void didUpdateWidget(covariant AdminUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || oldWidget.name != widget.name) {
      _loadAvatar();
    }
  }

  Future<void> _loadAvatar() async {
    final userId = widget.userId;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _avatarBytes = null;
          _loading = false;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
    });

    final result = await AdminApiClient.instance.getAvatar(userId);
    if (!mounted) return;

    setState(() {
      _avatarBytes = result.data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveName = (widget.name == null || widget.name!.trim().isEmpty)
        ? 'Admin'
        : widget.name!;

    if (_avatarBytes != null) {
      return Container(
        width: widget.size,
        height: widget.size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.size / 2),
        ),
        child: Image.memory(
          _avatarBytes!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => MuSheetAvatar(
            name: effectiveName,
            size: widget.size,
          ),
        ),
      );
    }

    if (_loading) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.avatarGradientStart, AppColors.avatarGradientEnd],
          ),
          borderRadius: BorderRadius.circular(widget.size / 2),
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return MuSheetAvatar(name: effectiveName, size: widget.size);
  }
}

class AdminAppWordmark extends StatelessWidget {
  final bool compact;

  const AdminAppWordmark({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return MuSheetWordmark(
      compact: compact,
      subtitle: 'Admin Workspace',
    );
  }
}

class AdminNavDestination {
  final IconData icon;
  final String label;
  final String path;

  const AdminNavDestination({
    required this.icon,
    required this.label,
    required this.path,
  });
}

class AdminSidebarNav extends StatelessWidget {
  final List<AdminNavDestination> destinations;
  final String currentPath;

  const AdminSidebarNav({
    super.key,
    required this.destinations,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: destinations
          .map(
            (destination) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AdminSidebarNavTile(
                destination: destination,
                selected: currentPath == destination.path,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AdminSidebarNavTile extends StatelessWidget {
  final AdminNavDestination destination;
  final bool selected;

  const _AdminSidebarNavTile({
    required this.destination,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.go(destination.path),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue50 : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.blue100 : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected ? AppColors.blue600 : AppColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  destination.icon,
                  size: 18,
                  color: selected ? Colors.white : AppColors.gray700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destination.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            selected ? AppColors.blue600 : AppColors.gray700,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ),
              if (selected)
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.blue600,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminToast {
  static void success(BuildContext context, String message) {
    _show(context, message, AppColors.emerald600, LucideIcons.circleCheck);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, AppColors.red600, LucideIcons.circleAlert);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, AppColors.blue600, LucideIcons.info);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gray200),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.gray800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
