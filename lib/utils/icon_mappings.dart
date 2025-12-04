import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Icon mappings from Material Icons to Lucide Icons
/// This ensures consistent icon usage across the app matching Figma design
class AppIcons {
  // Navigation (bottom bar)
  static const home = LucideIcons.house;
  static const homeOutlined = LucideIcons.house;
  static const libraryMusic = LucideIcons.library;  // Library tab uses library building icon
  static const libraryMusicOutlined = LucideIcons.library;
  static const people = LucideIcons.users;
  static const peopleOutline = LucideIcons.users;
  static const settings = LucideIcons.settings;
  static const settingsOutlined = LucideIcons.settings;
  
  // Setlist icon (used in Library tab's Setlists section and everywhere setlists appear)
  static const setlistIcon = LucideIcons.listMusic;
  
  // Common Actions
  static const add = LucideIcons.plus;
  static const close = LucideIcons.x;
  static const search = LucideIcons.search;
  static const edit = LucideIcons.pencil;
  static const delete = LucideIcons.trash2;
  static const share = LucideIcons.share2;
  static const check = LucideIcons.check;
  
  // Navigation & Direction
  static const chevronRight = LucideIcons.chevronRight;
  static const chevronLeft = LucideIcons.chevronLeft;
  static const chevronDown = LucideIcons.chevronDown;
  static const chevronUp = LucideIcons.chevronUp;
  static const keyboardArrowDown = LucideIcons.chevronDown;
  static const arrowBack = LucideIcons.arrowLeft;
  static const arrowForward = LucideIcons.arrowRight;
  static const arrowUp = LucideIcons.arrowUp;
  static const arrowDown = LucideIcons.arrowDown;
  
  // Sorting
  static const sortAsc = LucideIcons.arrowUpNarrowWide;
  static const sortDesc = LucideIcons.arrowDownWideNarrow;
  static const listOrdered = LucideIcons.listOrdered;
  static const clock = LucideIcons.clock;
  static const alphabetical = LucideIcons.aLargeSmall;
  static const calendarClock = LucideIcons.calendarClock;
  
  // Music & Media
  static const musicNote = LucideIcons.music;
  static const metronome = LucideIcons.drum;
  static const playArrow = LucideIcons.play;
  static const stop = LucideIcons.square;
  static const pause = LucideIcons.pause;
  static const mic = LucideIcons.mic;
  static const micOff = LucideIcons.micOff;
  static const speed = LucideIcons.gauge;
  static const playlistPlay = LucideIcons.listMusic;
  
  // Editing & Drawing
  static const undo = LucideIcons.undo;
  static const redo = LucideIcons.redo;
  static const autoFixHigh = LucideIcons.eraser;
  static const dragHandle = LucideIcons.gripVertical;
  
  // Files & Documents
  static const pictureAsPdfOutlined = LucideIcons.fileText;
  static const upload = LucideIcons.upload;
  
  // Communication
  static const notifications = LucideIcons.bell;
  static const notificationsOutlined = LucideIcons.bell;
  static const email = LucideIcons.mail;
  
  // Time & Status
  static const accessTime = LucideIcons.clock;
  static const trendingUp = LucideIcons.trendingUp;
  
  // Settings & System
  static const bluetooth = LucideIcons.bluetooth;
  static const cloud = LucideIcons.cloud;
  static const helpOutline = LucideIcons.badgeQuestionMark;
  static const infoOutline = LucideIcons.badgeInfo;
  
  // Special
  static const workspacePremium = LucideIcons.award;
  static const fiberManualRecord = LucideIcons.circle;
}