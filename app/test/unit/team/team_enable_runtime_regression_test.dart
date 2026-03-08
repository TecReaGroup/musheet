library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('team enable runtime regression', () {
    late String uiStateSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      uiStateSource = File(
        '$projectRoot/lib/providers/ui_state_providers.dart',
      ).readAsStringSync();
    });

    test('team enabled UI state should not trigger team repository side effects directly', () {
      expect(
        uiStateSource.contains('leaveAllTeams()'),
        isFalse,
        reason:
            'BUG DETECTED: TeamEnabledNotifier still triggers leaveAllTeams() '
            'directly. UI state should not own destructive team runtime side '
            'effects.',
      );

      expect(
        uiStateSource.contains('teamsStateProvider.notifier').
            toString(),
        isNotEmpty,
      );

      expect(
        uiStateSource.contains('.refresh()'),
        isFalse,
        reason:
            'BUG DETECTED: TeamEnabledNotifier still triggers teams refresh '
            'directly. Team capability toggles should be coordinated by a '
            'dedicated runtime/coordinator layer.',
      );
    });
  });
}
