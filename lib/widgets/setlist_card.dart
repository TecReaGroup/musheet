import 'package:flutter/material.dart';
import '../models/setlist.dart';
import '../theme/app_colors.dart';

/// A reusable setlist card component used throughout the app
/// Displays setlist information with consistent styling
class SetlistCard extends StatelessWidget {
  final Setlist setlist;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDescription;
  final bool compact;

  const SetlistCard({
    super.key,
    required this.setlist,
    this.onTap,
    this.onLongPress,
    this.showDescription = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(compact ? 8 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Setlist Icon
              _buildIcon(),
              SizedBox(width: compact ? 8 : 12),
              // Setlist Info
              Expanded(
                child: _buildInfo(),
              ),
              // Chevron Icon (optional)
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.gray400,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: compact ? 40 : 48,
      height: compact ? 40 : 48,
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.library_music,
        size: 24,
        color: AppColors.emerald600,
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          setlist.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: compact ? 14 : 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Description (optional)
        if (showDescription && setlist.description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            setlist.description,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              color: AppColors.gray600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        // Metadata
        const SizedBox(height: 2),
        Text(
          '${setlist.scoreIds.length} ${setlist.scoreIds.length == 1 ? "score" : "scores"} • Created ${_formatDate(setlist.dateCreated)}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gray400,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}.${date.day}.${date.year}';
  }
}

/// A compact variant of SetlistCard for use in lists with limited space
class CompactSetlistCard extends StatelessWidget {
  final Setlist setlist;
  final VoidCallback? onTap;

  const CompactSetlistCard({
    super.key,
    required this.setlist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SetlistCard(
      setlist: setlist,
      onTap: onTap,
      showDescription: false,
      compact: true,
    );
  }
}

/// A setlist card with additional actions (edit, delete, share)
class SetlistCardWithActions extends StatelessWidget {
  final Setlist setlist;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  const SetlistCardWithActions({
    super.key,
    required this.setlist,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Setlist Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.library_music,
                      size: 24,
                      color: AppColors.emerald600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Setlist Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          setlist.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (setlist.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            setlist.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.gray600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          '${setlist.scoreIds.length} ${setlist.scoreIds.length == 1 ? "score" : "scores"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Action Buttons
              if (onEdit != null || onDelete != null || onShare != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.gray200),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (onEdit != null)
                      _ActionButton(
                        icon: Icons.edit,
                        label: 'Edit',
                        onTap: onEdit!,
                      ),
                    if (onShare != null)
                      _ActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        onTap: onShare!,
                      ),
                    if (onDelete != null)
                      _ActionButton(
                        icon: Icons.delete,
                        label: 'Delete',
                        onTap: onDelete!,
                        color: AppColors.red500,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.gray600;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: buttonColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: buttonColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}