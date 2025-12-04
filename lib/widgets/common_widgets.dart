import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mappings.dart';

// ============================================================================
// ICON CONTAINERS - 统一的图标容器样式
// ============================================================================

/// 渐变图标容器 - 用于卡片中的图标显示
/// 
/// 使用示例:
/// ```dart
/// GradientIconBox(
///   icon: AppIcons.musicNote,
///   gradientColors: [AppColors.blue50, AppColors.blue100],
///   iconColor: AppColors.blue550,
/// )
/// ```
class GradientIconBox extends StatelessWidget {
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconColor;
  final double size;
  final double iconSize;
  final double borderRadius;

  const GradientIconBox({
    super.key,
    required this.icon,
    required this.gradientColors,
    required this.iconColor,
    this.size = 48,
    this.iconSize = 24,
    this.borderRadius = 12,
  });

  /// Score 类型的图标盒子 (蓝色渐变)
  factory GradientIconBox.score({
    Key? key,
    double size = 48,
    double iconSize = 24,
  }) {
    return GradientIconBox(
      key: key,
      icon: AppIcons.musicNote,
      gradientColors: const [AppColors.blue50, AppColors.blue100],
      iconColor: AppColors.blue550,
      size: size,
      iconSize: iconSize,
    );
  }

  /// Setlist 类型的图标盒子 (绿色渐变)
  factory GradientIconBox.setlist({
    Key? key,
    double size = 48,
    double iconSize = 24,
  }) {
    return GradientIconBox(
      key: key,
      icon: AppIcons.setlistIcon,
      gradientColors: const [AppColors.emerald50, AppColors.emerald100],
      iconColor: AppColors.emerald550,
      size: size,
      iconSize: iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(icon, size: iconSize, color: iconColor),
    );
  }
}

/// 圆形头像图标 - 用于用户/团队成员头像
class AvatarIcon extends StatelessWidget {
  final String initial;
  final double size;
  final List<Color>? gradientColors;

  const AvatarIcon({
    super.key,
    required this.initial,
    this.size = 48,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? [AppColors.blue500, const Color(0xFF9333EA)],
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
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
// TAB BUTTONS - 统一的 Tab 按钮样式
// ============================================================================

/// 统一的 Tab 按钮组件
/// 
/// 替代 `_TabButton` 和 `_TeamTabButton`
class AppTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;
  final double iconSize;

  const AppTabButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? activeColor : AppColors.gray100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: isActive ? Colors.white : AppColors.gray600),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.gray600,
                  fontWeight: FontWeight.w500,
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
// CARDS - 统一的卡片组件
// ============================================================================

/// 基础列表卡片 - 带图标、标题、副标题和可选尾部
class ListCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final String? meta;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets padding;

  const ListCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.meta,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(fontSize: 14, color: AppColors.gray600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (meta != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta!,
                          style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Score 卡片快捷组件
class ScoreListCard extends StatelessWidget {
  final String title;
  final String composer;
  final String? meta;
  final VoidCallback? onTap;
  final bool showChevron;

  const ScoreListCard({
    super.key,
    required this.title,
    required this.composer,
    this.meta,
    this.onTap,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListCard(
      leading: GradientIconBox.score(),
      title: title,
      subtitle: composer,
      meta: meta ?? 'Personal',
      trailing: showChevron
          ? const Icon(AppIcons.chevronRight, color: AppColors.gray400)
          : null,
      onTap: onTap,
    );
  }
}

/// Setlist 卡片快捷组件
class SetlistListCard extends StatelessWidget {
  final String name;
  final String description;
  final int scoreCount;
  final String? source; // 'Personal' or 'Team'
  final VoidCallback? onTap;
  final bool showChevron;

  const SetlistListCard({
    super.key,
    required this.name,
    required this.description,
    required this.scoreCount,
    this.source,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final scoreSuffix = scoreCount == 1 ? 'score' : 'scores';
    final sourceText = source ?? 'Personal';
    
    return ListCard(
      leading: GradientIconBox.setlist(),
      title: name,
      subtitle: description.isNotEmpty ? description : null,
      meta: '$scoreCount $scoreSuffix • $sourceText',
      trailing: showChevron
          ? const Icon(AppIcons.chevronRight, color: AppColors.gray400)
          : null,
      onTap: onTap,
    );
  }
}

// ============================================================================
// SETTINGS ITEMS - 设置项组件
// ============================================================================

/// 设置列表项
class SettingsListItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showDivider;
  final bool isFirst;
  final bool isLast;

  const SettingsListItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.showDivider = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    // 根据位置计算圆角
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(12) : Radius.zero,
      bottom: isLast ? const Radius.circular(12) : Radius.zero,
    );

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.gray600),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label)),
                  trailing ?? const Icon(AppIcons.chevronRight, size: 20, color: AppColors.gray400),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.gray200),
      ],
    );
  }
}

/// 设置组容器
class SettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SettingsGroup({
    super.key,
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              title!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gray500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// EMPTY STATES - 空状态组件
// ============================================================================

/// 通用空状态组件
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor = AppColors.gray300,
  });

  /// 空 Scores 状态
  factory EmptyState.scores({
    Key? key,
    Widget? action,
  }) {
    return EmptyState(
      key: key,
      icon: AppIcons.musicNote,
      title: 'No scores yet',
      subtitle: 'Import your first PDF score to get started',
      action: action,
    );
  }

  /// 空 Setlists 状态
  factory EmptyState.setlists({
    Key? key,
    Widget? action,
  }) {
    return EmptyState(
      key: key,
      icon: AppIcons.setlistIcon,
      title: 'No setlists yet',
      subtitle: 'Create a setlist to organize your performance repertoire',
      action: action,
    );
  }

  /// 搜索无结果状态
  factory EmptyState.noSearchResults({Key? key}) {
    return EmptyState(
      key: key,
      icon: AppIcons.search,
      title: 'No results found',
      subtitle: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, color: AppColors.gray600),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 14, color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MODALS - 模态框组件
// ============================================================================

/// 底部弹出的半透明遮罩层
class ModalBackdrop extends StatelessWidget {
  final VoidCallback onTap;
  final double opacity;

  const ModalBackdrop({
    super.key,
    required this.onTap,
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onTap,
        child: Container(color: Colors.black.withValues(alpha: opacity)),
      ),
    );
  }
}

/// 居中弹窗容器
class CenteredModal extends StatelessWidget {
  final Widget child;
  final double widthFactor;
  final double? maxWidth;
  final double? maxHeight;
  final EdgeInsets padding;

  const CenteredModal({
    super.key,
    required this.child,
    this.widthFactor = 0.9,
    this.maxWidth = 400,
    this.maxHeight,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * widthFactor,
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? double.infinity,
          maxHeight: maxHeight ?? double.infinity,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// 底部弹窗容器
class BottomSheetModal extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets padding;

  const BottomSheetModal({
    super.key,
    required this.child,
    this.maxWidth = 500,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

// ============================================================================
// PAGE HEADERS - 页面头部组件
// ============================================================================

/// 标准页面头部
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        24 + MediaQuery.of(context).padding.top,
        16,
        subtitle != null ? 16 : 24,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 14, color: AppColors.gray600),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

// ============================================================================
// STAT CARDS - 统计卡片组件
// ============================================================================

/// 首页统计卡片
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    this.onTap,
  });

  /// Scores 统计卡片
  factory StatCard.scores({
    Key? key,
    required int count,
    VoidCallback? onTap,
  }) {
    return StatCard(
      key: key,
      icon: AppIcons.musicNote,
      label: 'Scores',
      count: count,
      backgroundColor: AppColors.blue50,
      borderColor: AppColors.blue100,
      iconColor: AppColors.blue600,
      textColor: AppColors.blue600,
      onTap: onTap,
    );
  }

  /// Setlists 统计卡片
  factory StatCard.setlists({
    Key? key,
    required int count,
    VoidCallback? onTap,
  }) {
    return StatCard(
      key: key,
      icon: AppIcons.setlistIcon,
      label: 'Setlists',
      count: count,
      backgroundColor: AppColors.emerald50,
      borderColor: AppColors.emerald100,
      iconColor: AppColors.emerald600,
      textColor: AppColors.emerald600,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 14, color: textColor)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: const TextStyle(fontSize: 24, color: AppColors.gray900),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION HEADERS - 区块标题组件
// ============================================================================

/// 带图标的区块标题
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onViewAll;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.gray600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }
}

// ============================================================================
// NUMBER BADGE - 数字标记组件
// ============================================================================

/// 圆形数字标记
class NumberBadge extends StatelessWidget {
  final int number;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const NumberBadge({
    super.key,
    required this.number,
    this.size = 28,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.gray100,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: size * 0.43,
            color: textColor ?? AppColors.gray600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TOOL BUTTONS - 工具按钮组件
// ============================================================================

/// 工具栏按钮
class ToolButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isDisabled;
  final Color activeColor;
  final VoidCallback? onPressed;
  final double size;

  const ToolButton({
    super.key,
    required this.icon,
    this.isActive = false,
    this.isDisabled = false,
    this.activeColor = AppColors.blue500,
    this.onPressed,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: size * 0.5,
            color: isDisabled
                ? AppColors.gray300
                : isActive
                    ? activeColor
                    : AppColors.gray500,
          ),
        ),
      ),
    );
  }
}
