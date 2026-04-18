import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_colors.dart';

class MuSheetIcons {
  MuSheetIcons._();

  static const IconData home = LucideIcons.house;
  static const IconData homeOutlined = LucideIcons.house;
  static const IconData libraryMusic = LucideIcons.library;
  static const IconData libraryMusicOutlined = LucideIcons.library;
  static const IconData people = LucideIcons.users;
  static const IconData peopleOutline = LucideIcons.users;
  static const IconData settings = LucideIcons.settings;
  static const IconData settingsOutlined = LucideIcons.settings;
  static const IconData setlistIcon = LucideIcons.listMusic;
  static const IconData add = LucideIcons.plus;
  static const IconData close = LucideIcons.x;
  static const IconData search = LucideIcons.search;
  static const IconData edit = LucideIcons.squarePen;
  static const IconData delete = LucideIcons.trash2;
  static const IconData share = LucideIcons.share2;
  static const IconData check = LucideIcons.check;
  static const IconData copy = LucideIcons.copy;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData chevronUp = LucideIcons.chevronUp;
  static const IconData keyboardArrowDown = LucideIcons.chevronDown;
  static const IconData arrowBack = LucideIcons.arrowLeft;
  static const IconData arrowForward = LucideIcons.arrowRight;
  static const IconData arrowUp = LucideIcons.arrowUp;
  static const IconData arrowDown = LucideIcons.arrowDown;
  static const IconData sortAsc = LucideIcons.arrowUpNarrowWide;
  static const IconData sortDesc = LucideIcons.arrowDownWideNarrow;
  static const IconData listOrdered = LucideIcons.listOrdered;
  static const IconData clock = LucideIcons.clock;
  static const IconData alphabetical = LucideIcons.aLargeSmall;
  static const IconData calendarClock = LucideIcons.calendarClock;
  static const IconData musicNote = LucideIcons.music;
  static const IconData metronome = LucideIcons.drum;
  static const IconData playArrow = LucideIcons.play;
  static const IconData play = LucideIcons.play;
  static const IconData stop = LucideIcons.square;
  static const IconData pause = LucideIcons.pause;
  static const IconData mic = LucideIcons.mic;
  static const IconData micOff = LucideIcons.micOff;
  static const IconData speed = LucideIcons.gauge;
  static const IconData playlistPlay = LucideIcons.listMusic;
  static const IconData piano = LucideIcons.piano;
  static const IconData keyboardMusic = LucideIcons.piano;
  static const IconData drum = LucideIcons.drum;
  static const IconData guitar = LucideIcons.guitar;
  static const IconData circleSlash = LucideIcons.circleSlash;
  static const IconData person = LucideIcons.user;
  static const IconData rotateCcwKey = LucideIcons.rotateCcwKey;
  static const IconData undo = LucideIcons.undo;
  static const IconData redo = LucideIcons.redo;
  static const IconData autoFixHigh = LucideIcons.eraser;
  static const IconData dragHandle = LucideIcons.gripVertical;
  static const IconData rotateCcw = LucideIcons.rotateCcw;
  static const IconData rotateCw = LucideIcons.rotateCw;
  static const IconData pictureAsPdfOutlined = LucideIcons.fileText;
  static const IconData upload = LucideIcons.upload;
  static const IconData notifications = LucideIcons.bell;
  static const IconData notificationsOutlined = LucideIcons.bell;
  static const IconData email = LucideIcons.mail;
  static const IconData accessTime = LucideIcons.clock;
  static const IconData trendingUp = LucideIcons.trendingUp;
  static const IconData bluetooth = LucideIcons.bluetooth;
  static const IconData cloud = LucideIcons.cloud;
  static const IconData cloudOff = LucideIcons.cloudOff;
  static const IconData helpOutline = LucideIcons.handHelping;
  static const IconData infoOutline = LucideIcons.info;
  static const IconData globe = LucideIcons.globe;
  static const IconData fileText = LucideIcons.fileText;
  static const IconData star = LucideIcons.star;
  static const IconData bookOpen = LucideIcons.bookOpen;
  static const IconData mail = LucideIcons.mail;
  static const IconData bug = LucideIcons.bug;
  static const IconData lightbulb = LucideIcons.lightbulb;
  static const IconData refreshCw = LucideIcons.refreshCw;
  static const IconData refreshCcw = LucideIcons.refreshCcw;
  static const IconData sync = LucideIcons.refreshCcw;
  static const IconData wifi = LucideIcons.wifi;
  static const IconData wifiOff = LucideIcons.wifiOff;
  static const IconData workspacePremium = LucideIcons.award;
  static const IconData fiberManualRecord = LucideIcons.circle;
  static const IconData camera = LucideIcons.camera;
  static const IconData image = LucideIcons.image;

  static Widget appIconSvg({double size = 24, BoxFit fit = BoxFit.contain}) {
    return SvgPicture.asset(
      'assets/app_icon.svg',
      package: 'musheet_shared_ui',
      width: size,
      height: size,
      fit: fit,
    );
  }

  static ImageProvider<Object> appIconImageProvider() {
    return const AssetImage(
      'assets/app_icon.png',
      package: 'musheet_shared_ui',
    );
  }
}

class MuSheetBrandMark extends StatelessWidget {
  final double size;
  final double radius;
  final bool useSvg;
  final List<Color> gradientColors;
  final List<BoxShadow>? boxShadow;

  const MuSheetBrandMark({
    super.key,
    this.size = 48,
    this.radius = 14,
    this.useSvg = true,
    this.gradientColors = const [AppColors.indigo500, AppColors.blue550],
    this.boxShadow,
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
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: boxShadow ??
            const [
              BoxShadow(
                color: Color(0x144F46E5),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: useSvg
            ? Padding(
                padding: EdgeInsets.all(size * 0.16),
                child: Image(
                  image: MuSheetIcons.appIconImageProvider(),
                  fit: BoxFit.contain,
                ),
              )
            : Icon(
                MuSheetIcons.musicNote,
                color: Colors.white,
                size: size * 0.5,
              ),
      ),
    );
  }
}

class MuSheetWordmark extends StatelessWidget {
  final String subtitle;
  final bool compact;

  const MuSheetWordmark({
    super.key,
    this.subtitle = '',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.gray900,
        );

    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.gray500,
          fontWeight: FontWeight.w500,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MuSheetBrandMark(
          size: compact ? 38 : 46,
          radius: compact ? 12 : 14,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('MuSheet', style: titleStyle),
            if (subtitle.isNotEmpty) Text(subtitle, style: subtitleStyle),
          ],
        ),
      ],
    );
  }
}

class MuSheetAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double? fontSize;

  const MuSheetAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.fontSize,
  });

  String get initials {
    final value = name.trim();
    if (value.isEmpty) return 'M';

    final parts = value.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }

    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.avatarGradientStart, AppColors.avatarGradientEnd],
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.avatarText,
          fontSize: fontSize ?? size * 0.34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class MuSheetLoadingIndicator extends StatelessWidget {
  final String? message;
  final bool centered;

  const MuSheetLoadingIndicator({
    super.key,
    this.message,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MuSheetBrandMark(size: 52, radius: 16),
        const SizedBox(height: 18),
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.indigo500,
            backgroundColor: AppColors.blue100,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 14),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );

    if (centered) {
      return Center(child: content);
    }

    return content;
  }
}
