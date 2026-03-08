library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('settings overlay regression', () {
    late String settingsSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      settingsSource = File('$projectRoot/lib/screens/settings_screen.dart')
          .readAsStringSync();
    });

    test('settings screen should not manage account switcher with manual overlay infrastructure', () {
      expect(
        settingsSource.contains('OverlayEntry'),
        isFalse,
        reason:
            'BUG DETECTED: SettingsScreen still uses manual OverlayEntry lifecycle '
            'for the account switcher, which is fragile during route and auth '
            'transitions.',
      );

      expect(
        settingsSource.contains('LayerLink'),
        isFalse,
        reason:
            'BUG DETECTED: SettingsScreen still uses LayerLink-based anchored '
            'overlay logic instead of a declarative popup/menu widget.',
      );

      expect(
        settingsSource.contains('_accountCardKey'),
        isFalse,
        reason:
            'BUG DETECTED: SettingsScreen still relies on a GlobalKey anchor for '
            'the account switcher. The refactor should remove this fragile anchor '
            'pattern entirely.',
      );
    });

    test('account switcher should anchor below the profile card and dismiss from backdrop tap', () {
      expect(
        settingsSource.contains('showGeneralDialog<void>('),
        isTrue,
        reason:
            'SettingsScreen should present the account switcher with a dismissible '
            'dialog so it can be positioned directly below the profile card.',
      );

      expect(
        settingsSource.contains('barrierDismissible: true'),
        isTrue,
        reason:
            'BUG DETECTED: The account switcher should dismiss when the user taps '
            'the backdrop.',
      );

      expect(
        settingsSource.contains('top: cardBottomRight.dy + verticalSpacing'),
        isTrue,
        reason:
            'BUG DETECTED: The account switcher should be positioned directly '
            'below the profile card.',
      );

      expect(
        settingsSource.contains('showModalBottomSheet<void>('),
        isFalse,
        reason:
            'BUG DETECTED: The account switcher should no longer use a bottom '
            'sheet now that the menu is anchored below the profile card.',
      );
    });
  });
}
