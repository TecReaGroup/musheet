import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

// ============================================================================
// STAT CARDS - Dashboard statistics cards (Dark theme)
// ============================================================================

class AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor = AppColors.indigo500,
    this.onTap,
  });

  factory AdminStatCard.users({
    Key? key,
    required int count,
    VoidCallback? onTap,
  }) {
    return AdminStatCard(
      key: key,
      icon: LucideIcons.users,
      label: 'Total Users',
      value: '$count',
      accentColor: AppColors.indigo500,
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
      icon: LucideIcons.userCheck,
      label: 'Active Users',
      value: '$count',
      accentColor: AppColors.emerald500,
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
      accentColor: AppColors.purple500,
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
      icon: LucideIcons.music,
      label: 'Scores',
      value: '$count',
      accentColor: AppColors.yellow500,
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
      accentColor: AppColors.gray400,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.slate800,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: AppColors.slate700,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate700),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DATA TABLE CARD - Wrapper for data tables (Dark theme)
// ============================================================================

class DataTableCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final List<Widget>? actions;

  const DataTableCard({
    super.key,
    required this.title,
    this.icon,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: AppColors.gray400),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
          Divider(color: AppColors.slate700, height: 1),
          child,
        ],
      ),
    );
  }
}

// ============================================================================
// BADGES - Status badges (Dark theme)
// ============================================================================

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
      backgroundColor: AppColors.indigo500.withValues(alpha: 0.2),
      textColor: AppColors.indigo400,
      icon: LucideIcons.shield,
    );
  }

  factory StatusBadge.user({Key? key}) {
    return StatusBadge(
      key: key,
      label: 'User',
      backgroundColor: AppColors.gray600.withValues(alpha: 0.3),
      textColor: AppColors.gray300,
    );
  }

  factory StatusBadge.active({Key? key}) {
    return StatusBadge(
      key: key,
      label: 'Active',
      backgroundColor: AppColors.emerald500.withValues(alpha: 0.2),
      textColor: AppColors.emerald400,
      icon: LucideIcons.check,
    );
  }

  factory StatusBadge.disabled({Key? key}) {
    return StatusBadge(
      key: key,
      label: 'Disabled',
      backgroundColor: AppColors.red500.withValues(alpha: 0.2),
      textColor: AppColors.red400,
      icon: LucideIcons.ban,
    );
  }

  factory StatusBadge.count({
    Key? key,
    required int count,
    required IconData icon,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.indigo500;
    return StatusBadge(
      key: key,
      label: '$count',
      backgroundColor: effectiveColor.withValues(alpha: 0.15),
      textColor: effectiveColor,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACTION BUTTONS - Icon action buttons for tables
// ============================================================================

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
        color ?? (isDanger ? AppColors.red400 : AppColors.gray400);

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          hoverColor: AppColors.slate700,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 16,
              color: onPressed != null ? effectiveColor : AppColors.gray600,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.gray600),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.gray300,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// LOADING INDICATOR
// ============================================================================

class AdminLoadingIndicator extends StatelessWidget {
  final String? message;

  const AdminLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.indigo500),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// CONFIRM DIALOG
// ============================================================================

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;
  final VoidCallback? onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDanger = false,
    this.onConfirm,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.slate800,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Text(message, style: TextStyle(color: AppColors.gray300)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDanger ? AppColors.red500 : AppColors.indigo500,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

// ============================================================================
// PAGINATION CONTROLS
// ============================================================================

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.hasMore,
    this.isLoading = false,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (currentPage == 0 && !hasMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: currentPage > 0 && !isLoading ? onPrevious : null,
            icon: const Icon(LucideIcons.chevronLeft, size: 16),
            label: const Text('Previous'),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.indigo600,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${currentPage + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: hasMore && !isLoading ? onNext : null,
            icon: const Text('Next'),
            label: const Icon(LucideIcons.chevronRight, size: 16),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// USER AVATAR
// ============================================================================

class AdminUserAvatar extends StatelessWidget {
  final String? name;
  final double size;

  const AdminUserAvatar({
    super.key,
    this.name,
    this.size = 40,
  });

  String get _initials {
    if (name == null || name!.isEmpty) return 'A';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name!.substring(0, name!.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.indigo500, AppColors.purple500],
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TOAST NOTIFICATIONS
// ============================================================================

class AdminToast {
  static void success(BuildContext context, String message) {
    _show(context, message, AppColors.emerald500, LucideIcons.check);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, AppColors.red500, LucideIcons.circleAlert);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, AppColors.indigo500, LucideIcons.info);
  }

  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
