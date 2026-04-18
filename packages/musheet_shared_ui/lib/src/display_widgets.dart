import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'branding_widgets.dart';

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

  factory GradientIconBox.score({
    Key? key,
    double size = 48,
    double iconSize = 24,
  }) {
    return GradientIconBox(
      key: key,
      icon: MuSheetIcons.musicNote,
      gradientColors: const [AppColors.blue50, AppColors.blue100],
      iconColor: AppColors.blue550,
      size: size,
      iconSize: iconSize,
    );
  }

  factory GradientIconBox.setlist({
    Key? key,
    double size = 48,
    double iconSize = 24,
  }) {
    return GradientIconBox(
      key: key,
      icon: MuSheetIcons.setlistIcon,
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ??
              const [
                AppColors.avatarGradientStart,
                AppColors.avatarGradientEnd,
              ],
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
