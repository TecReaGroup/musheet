import 'package:flutter/material.dart';
import '../models/score.dart';
import '../theme/app_colors.dart';

/// A reusable score card component used throughout the app
/// Displays score information with consistent styling
class ScoreCard extends StatelessWidget {
  final Score score;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDateAdded;
  final bool compact;

  const ScoreCard({
    super.key,
    required this.score,
    this.onTap,
    this.onLongPress,
    this.showDateAdded = true,
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
              // Score Icon
              _buildIcon(),
              SizedBox(width: compact ? 8 : 12),
              // Score Info
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
    // Get thumbnail from first instrument score
    final thumbnail = score.firstInstrumentScore?.thumbnail;
    
    return Container(
      width: compact ? 40 : 48,
      height: compact ? 40 : 48,
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: thumbnail != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.music_note, size: 24, color: AppColors.blue600),
              ),
            )
          : const Icon(Icons.music_note, size: 24, color: AppColors.blue600),
    );
  }

  Widget _buildInfo() {
    // Get total annotation count across all instrument scores
    final annotationCount = score.totalAnnotationCount;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          score.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: compact ? 14 : 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // Composer
        Text(
          score.composer,
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            color: AppColors.gray600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Date Added (optional)
        if (showDateAdded) ...[
          const SizedBox(height: 2),
          Text(
            'Added ${_formatDate(score.dateAdded)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray400,
            ),
          ),
        ],
        // Annotations Badge (if has annotations)
        if (annotationCount > 0) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit,
                  size: 10,
                  color: AppColors.blue600,
                ),
                const SizedBox(width: 4),
                Text(
                  '$annotationCount annotation${annotationCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.blue600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}.${date.day}.${date.year}';
  }
}

/// A compact variant of ScoreCard for use in lists with limited space
class CompactScoreCard extends StatelessWidget {
  final Score score;
  final VoidCallback? onTap;

  const CompactScoreCard({
    super.key,
    required this.score,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScoreCard(
      score: score,
      onTap: onTap,
      showDateAdded: false,
      compact: true,
    );
  }
}

/// A score card with a leading number indicator (for use in setlists)
class NumberedScoreCard extends StatelessWidget {
  final Score score;
  final int number;
  final VoidCallback? onTap;
  final bool isDraggable;

  const NumberedScoreCard({
    super.key,
    required this.score,
    required this.number,
    this.onTap,
    this.isDraggable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray100),
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
              // Drag Handle (if draggable)
              if (isDraggable) ...[
                const Icon(Icons.drag_handle, size: 18, color: AppColors.gray300),
                const SizedBox(width: 12),
              ],
              // Number Badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gray100, AppColors.gray200],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Score Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      score.composer,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}