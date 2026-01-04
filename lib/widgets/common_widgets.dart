import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mappings.dart';

// ============================================================================
// ICON CONTAINERS - Unified icon container styles
// ============================================================================

/// Gradient icon container - for icon display in cards
///
/// Usage example:
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

  /// Score type icon box (blue gradient)
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

  /// Setlist type icon box (green gradient)
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

/// Circular avatar icon - for user/team member avatars
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
// TAB BUTTONS - Unified tab button styles
// ============================================================================

/// Unified tab button component
///
/// Replaces `_TabButton` and `_TeamTabButton`
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
// CARDS - Unified card components
// ============================================================================

/// Base list card - with icon, title, subtitle and optional trailing
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

/// Score card shortcut component
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

/// Setlist card shortcut component
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
// SETTINGS ITEMS - Settings item components
// ============================================================================

/// Settings list item
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
    // Calculate border radius based on position
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

/// Settings group container
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
// EMPTY STATES - Empty state components
// ============================================================================

/// Generic empty state component
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

  /// Empty Scores state
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

  /// Empty Setlists state
  factory EmptyState.setlists({
    Key? key,
    Widget? action,
  }) {
    return EmptyState(
      key: key,
      icon: AppIcons.setlistIcon,
      title: 'No setlists yet',
      subtitle: 'Create a setlist to organize your scores',
      action: action,
    );
  }

  /// No search results state
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
// MODALS - Modal components
// ============================================================================

/// Semi-transparent backdrop overlay
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

/// Centered modal container
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

/// Bottom sheet modal container
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
// PAGE HEADERS - Page header components
// ============================================================================

/// Standard page header
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
// STAT CARDS - Statistics card components
// ============================================================================

/// Home page statistics card
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

  /// Scores statistics card
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

  /// Setlists statistics card
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
// SECTION HEADERS - Section header components
// ============================================================================

/// Section header with icon
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
// NUMBER BADGE - Number badge components
// ============================================================================

/// Circular number badge
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
// SWIPEABLE LIST ITEM - Swipe to reveal delete button
// ============================================================================

/// Swipeable list item with delete action (left swipe)
/// Used in Library and Team screens for scores and setlists
class SwipeableListItem extends StatelessWidget {
  final String id;
  final Widget child;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final String? swipedItemId;
  final double swipeOffset;
  final bool isDragging;
  final bool hasSwiped;
  final void Function(String id, Offset position) onSwipeStart;
  final void Function(Offset position) onSwipeUpdate;
  final VoidCallback onSwipeEnd;
  
  static const double swipeThreshold = 32.0;
  static const double swipeMaxOffset = 64.0;

  const SwipeableListItem({
    super.key,
    required this.id,
    required this.child,
    required this.onDelete,
    required this.onTap,
    required this.swipedItemId,
    required this.swipeOffset,
    required this.isDragging,
    required this.hasSwiped,
    required this.onSwipeStart,
    required this.onSwipeUpdate,
    required this.onSwipeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isSwipedItem = swipedItemId == id;
    final offset = isSwipedItem ? swipeOffset : 0.0;
    final showDeleteButton = offset < -swipeThreshold;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Red background + delete button
            Positioned.fill(
              child: Container(
                color: AppColors.red500,
                child: Row(
                  children: [
                    const Spacer(),
                    // Center trash icon in exposed area (width = -offset)
                    SizedBox(
                      width: -offset,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: showDeleteButton ? 1.0 : 0.0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: showDeleteButton ? onDelete : null,
                          child: const SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: Icon(AppIcons.delete, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Card content
            GestureDetector(
              onHorizontalDragStart: (details) => onSwipeStart(id, details.globalPosition),
              onHorizontalDragUpdate: (details) => onSwipeUpdate(details.globalPosition),
              onHorizontalDragEnd: (_) => onSwipeEnd(),
              child: AnimatedContainer(
                duration: Duration(milliseconds: isDragging ? 0 : 200),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(offset, 0, 0),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      if (showDeleteButton) {
                        // Reset swipe state - handled by parent
                        onSwipeEnd();
                      } else if (!hasSwiped) {
                        onTap();
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mixin to add swipe handling capabilities to a StatefulWidget
/// Usage: Add `with SwipeHandlerMixin` to your State class
mixin SwipeHandlerMixin<T extends StatefulWidget> on State<T> {
  String? swipedItemId;
  double swipeOffset = 0;
  Offset? dragStart;
  bool isDragging = false;
  bool hasSwiped = false;

  static const double swipeThreshold = 32.0;
  static const double swipeMaxOffset = 64.0;

  void handleSwipeStart(String itemId, Offset position) {
    if (swipedItemId != null && swipedItemId != itemId) {
      setState(() {
        swipeOffset = 0;
        swipedItemId = null;
      });
    }
    setState(() {
      dragStart = position;
      swipedItemId = itemId;
      isDragging = true;
      hasSwiped = false;
    });
  }

  void handleSwipeUpdate(Offset position) {
    if (dragStart == null || !isDragging) return;
    
    final deltaX = position.dx - dragStart!.dx;
    final newOffset = deltaX.clamp(-swipeMaxOffset, 0.0);
    setState(() {
      swipeOffset = newOffset;
      if (deltaX.abs() > 5) {
        hasSwiped = true;
      }
    });
  }

  void handleSwipeEnd() {
    if (!isDragging) return;
    
    setState(() {
      if (swipeOffset < -swipeThreshold) {
        swipeOffset = -swipeMaxOffset;
      } else {
        swipeOffset = 0;
        swipedItemId = null;
      }
      dragStart = null;
      isDragging = false;
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          hasSwiped = false;
        });
      }
    });
  }

  void resetSwipeState() {
    setState(() {
      swipedItemId = null;
      swipeOffset = 0;
    });
  }
}

// ============================================================================
// ITEM CARDS - Unified card components for list items
// ============================================================================

/// Score card with arrow button for detail navigation
/// Used in Library and Team screens
class ScoreItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback? onTap;
  final VoidCallback? onArrowTap;

  const ScoreItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.meta,
    this.onTap,
    this.onArrowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Row(
        children: [
          GradientIconBox.score(),
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
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: AppColors.gray600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  meta,
                  style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                ),
              ],
            ),
          ),
          if (onArrowTap != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onArrowTap,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(AppIcons.chevronRight, color: AppColors.gray400),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Setlist card with arrow button for detail navigation
/// Used in Library and Team screens
class SetlistItemCard extends StatelessWidget {
  final String name;
  final String description;
  final int scoreCount;
  final String source; // 'Personal' or 'Team'
  final VoidCallback? onTap;
  final VoidCallback? onArrowTap;

  const SetlistItemCard({
    super.key,
    required this.name,
    required this.description,
    required this.scoreCount,
    this.source = 'Personal',
    this.onTap,
    this.onArrowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Row(
        children: [
          GradientIconBox.setlist(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: AppColors.gray600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$scoreCount ${scoreCount == 1 ? "score" : "scores"} • $source',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                ),
              ],
            ),
          ),
          if (onArrowTap != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onArrowTap,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(AppIcons.chevronRight, color: AppColors.gray400),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// SWIPEABLE ITEM CARDS - High-level components combining swipe + card
// ============================================================================

/// Swipeable Score Card - combines SwipeableListItem with ScoreItemCard
/// Reduces boilerplate when using score cards with swipe-to-delete
class SwipeableScoreCard extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final String meta;
  
  // Swipe state (from SwipeHandlerMixin)
  final String? swipedItemId;
  final double swipeOffset;
  final bool isDragging;
  final bool hasSwiped;
  
  // Callbacks
  final void Function(String id, Offset position) onSwipeStart;
  final void Function(Offset position) onSwipeUpdate;
  final VoidCallback onSwipeEnd;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onArrowTap;

  const SwipeableScoreCard({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.swipedItemId,
    required this.swipeOffset,
    required this.isDragging,
    required this.hasSwiped,
    required this.onSwipeStart,
    required this.onSwipeUpdate,
    required this.onSwipeEnd,
    required this.onDelete,
    required this.onTap,
    required this.onArrowTap,
  });

  @override
  Widget build(BuildContext context) {
    return SwipeableListItem(
      id: id,
      swipedItemId: swipedItemId,
      swipeOffset: swipeOffset,
      isDragging: isDragging,
      hasSwiped: hasSwiped,
      onSwipeStart: onSwipeStart,
      onSwipeUpdate: onSwipeUpdate,
      onSwipeEnd: onSwipeEnd,
      onDelete: onDelete,
      onTap: onTap,
      child: ScoreItemCard(
        title: title,
        subtitle: subtitle,
        meta: meta,
        onArrowTap: onArrowTap,
      ),
    );
  }
}

/// Swipeable Setlist Card - combines SwipeableListItem with SetlistItemCard
/// Reduces boilerplate when using setlist cards with swipe-to-delete
class SwipeableSetlistCard extends StatelessWidget {
  final String id;
  final String name;
  final String description;
  final int scoreCount;
  final String source;
  
  // Swipe state (from SwipeHandlerMixin)
  final String? swipedItemId;
  final double swipeOffset;
  final bool isDragging;
  final bool hasSwiped;
  
  // Callbacks
  final void Function(String id, Offset position) onSwipeStart;
  final void Function(Offset position) onSwipeUpdate;
  final VoidCallback onSwipeEnd;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onArrowTap;

  const SwipeableSetlistCard({
    super.key,
    required this.id,
    required this.name,
    required this.description,
    required this.scoreCount,
    this.source = 'Personal',
    required this.swipedItemId,
    required this.swipeOffset,
    required this.isDragging,
    required this.hasSwiped,
    required this.onSwipeStart,
    required this.onSwipeUpdate,
    required this.onSwipeEnd,
    required this.onDelete,
    required this.onTap,
    required this.onArrowTap,
  });

  @override
  Widget build(BuildContext context) {
    return SwipeableListItem(
      id: id,
      swipedItemId: swipedItemId,
      swipeOffset: swipeOffset,
      isDragging: isDragging,
      hasSwiped: hasSwiped,
      onSwipeStart: onSwipeStart,
      onSwipeUpdate: onSwipeUpdate,
      onSwipeEnd: onSwipeEnd,
      onDelete: onDelete,
      onTap: onTap,
      child: SetlistItemCard(
        name: name,
        description: description,
        scoreCount: scoreCount,
        source: source,
        onArrowTap: onArrowTap,
      ),
    );
  }
}

// ============================================================================
// TOOL BUTTONS - Tool button components
// ============================================================================

/// Toolbar button
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
