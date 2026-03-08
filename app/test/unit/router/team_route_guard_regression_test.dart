library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('team route guard regression', () {
    late String routerSource;
    late String teamScreenSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      routerSource = File('$projectRoot/lib/router/app_router.dart')
          .readAsStringSync();
      teamScreenSource = File('$projectRoot/lib/screens/team_screen.dart')
          .readAsStringSync();
    });

    test('router should explicitly guard team route access', () {
      expect(
        routerSource.contains('AppRoutes.team'),
        isTrue,
        reason: 'Team route should remain registered in the stable router.',
      );

      expect(
        routerSource.contains('RouteCapabilityPolicy') &&
            routerSource.contains('decision = routeGuardPolicy.evaluate'),
        isTrue,
        reason:
            'BUG DETECTED: Router redirect logic still does not route Team '
            'access through the extracted capability policy layer.',
      );
    });

    test('team screen should not own anonymous gating itself', () {
      expect(
        teamScreenSource.contains("Sign in to access Team features."),
        isFalse,
        reason:
            'BUG DETECTED: TeamScreen still owns anonymous gating UI instead of '
            'letting the router guard/capability layer decide access.',
      );

      expect(
        teamScreenSource.contains('libraryMode != LibraryStorageMode.account'),
        isFalse,
        reason:
            'BUG DETECTED: TeamScreen still checks library mode directly for '
            'route access. This should move into router/capability policy.',
      );
    });
  });
}
