import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:musheet_shared_ui/musheet_shared_ui.dart';

/// App-local icon facade.
///
/// Shared MuSheet icon mappings live in
/// [`MuSheetIcons`](packages/musheet_shared_ui/lib/src/branding_widgets.dart:7).
/// App-only custom SVG widgets remain here.
class AppIcons {
  AppIcons._();

  static const home = MuSheetIcons.home;
  static const homeOutlined = MuSheetIcons.homeOutlined;
  static const libraryMusic = MuSheetIcons.libraryMusic;
  static const libraryMusicOutlined = MuSheetIcons.libraryMusicOutlined;
  static const people = MuSheetIcons.people;
  static const peopleOutline = MuSheetIcons.peopleOutline;
  static const settings = MuSheetIcons.settings;
  static const settingsOutlined = MuSheetIcons.settingsOutlined;
  static const setlistIcon = MuSheetIcons.setlistIcon;
  static const add = MuSheetIcons.add;
  static const close = MuSheetIcons.close;
  static const search = MuSheetIcons.search;
  static const edit = MuSheetIcons.edit;
  static const delete = MuSheetIcons.delete;
  static const share = MuSheetIcons.share;
  static const check = MuSheetIcons.check;
  static const copy = MuSheetIcons.copy;
  static const chevronRight = MuSheetIcons.chevronRight;
  static const chevronLeft = MuSheetIcons.chevronLeft;
  static const chevronDown = MuSheetIcons.chevronDown;
  static const chevronUp = MuSheetIcons.chevronUp;
  static const keyboardArrowDown = MuSheetIcons.keyboardArrowDown;
  static const arrowBack = MuSheetIcons.arrowBack;
  static const arrowForward = MuSheetIcons.arrowForward;
  static const arrowUp = MuSheetIcons.arrowUp;
  static const arrowDown = MuSheetIcons.arrowDown;
  static const sortAsc = MuSheetIcons.sortAsc;
  static const sortDesc = MuSheetIcons.sortDesc;
  static const listOrdered = MuSheetIcons.listOrdered;
  static const clock = MuSheetIcons.clock;
  static const alphabetical = MuSheetIcons.alphabetical;
  static const calendarClock = MuSheetIcons.calendarClock;
  static const musicNote = MuSheetIcons.musicNote;
  static const metronome = MuSheetIcons.metronome;
  static const playArrow = MuSheetIcons.playArrow;
  static const play = MuSheetIcons.play;
  static const stop = MuSheetIcons.stop;
  static const pause = MuSheetIcons.pause;
  static const mic = MuSheetIcons.mic;
  static const micOff = MuSheetIcons.micOff;
  static const speed = MuSheetIcons.speed;
  static const playlistPlay = MuSheetIcons.playlistPlay;
  static const piano = MuSheetIcons.piano;
  static const keyboardMusic = MuSheetIcons.keyboardMusic;
  static const drum = MuSheetIcons.drum;
  static const guitar = MuSheetIcons.guitar;
  static const circleSlash = MuSheetIcons.circleSlash;
  static const person = MuSheetIcons.person;
  static const rotateCcwKey = MuSheetIcons.rotateCcwKey;
  static const undo = MuSheetIcons.undo;
  static const redo = MuSheetIcons.redo;
  static const autoFixHigh = MuSheetIcons.autoFixHigh;
  static const dragHandle = MuSheetIcons.dragHandle;
  static const rotateCcw = MuSheetIcons.rotateCcw;
  static const rotateCw = MuSheetIcons.rotateCw;
  static const pictureAsPdfOutlined = MuSheetIcons.pictureAsPdfOutlined;
  static const upload = MuSheetIcons.upload;
  static const notifications = MuSheetIcons.notifications;
  static const notificationsOutlined = MuSheetIcons.notificationsOutlined;
  static const email = MuSheetIcons.email;
  static const accessTime = MuSheetIcons.accessTime;
  static const trendingUp = MuSheetIcons.trendingUp;
  static const bluetooth = MuSheetIcons.bluetooth;
  static const cloud = MuSheetIcons.cloud;
  static const cloudOff = MuSheetIcons.cloudOff;
  static const helpOutline = MuSheetIcons.helpOutline;
  static const infoOutline = MuSheetIcons.infoOutline;
  static const globe = MuSheetIcons.globe;
  static const fileText = MuSheetIcons.fileText;
  static const star = MuSheetIcons.star;
  static const bookOpen = MuSheetIcons.bookOpen;
  static const mail = MuSheetIcons.mail;
  static const bug = MuSheetIcons.bug;
  static const lightbulb = MuSheetIcons.lightbulb;
  static const refreshCw = MuSheetIcons.refreshCw;
  static const refreshCcw = MuSheetIcons.refreshCcw;
  static const sync = MuSheetIcons.sync;
  static const wifi = MuSheetIcons.wifi;
  static const wifiOff = MuSheetIcons.wifiOff;
  static const workspacePremium = MuSheetIcons.workspacePremium;
  static const fiberManualRecord = MuSheetIcons.fiberManualRecord;
  static const camera = MuSheetIcons.camera;
  static const image = MuSheetIcons.image;

  static Widget bassGuitar({double size = 24, Color? color}) {
    return SvgPicture.asset(
      'assets/icons/bass_guitar.svg',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }

  static Widget metronomeIcon({double size = 24, Color? color}) {
    return SvgPicture.asset(
      'assets/icons/metronome.svg',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }
}