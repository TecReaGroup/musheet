library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('router guard regression', () {
    late String routerSource;
    late String profileSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      routerSource = File('$projectRoot/lib/router/app_router.dart')
          .readAsStringSync();
      profileSource = File(
        '$projectRoot/lib/screens/settings/profile_screen.dart',
      ).readAsStringSync();
    });

    test('router should own redirect/guard logic for protected routes', () {
      expect(
        routerSource.contains('redirect:'),
        isTrue,
        reason:
            'BUG DETECTED: Stable router is missing explicit redirect/guard '
            'logic for protected routes like profile/team.',
      );
    });

    test('profile screen should not navigate away during build', () {
      expect(
        profileSource.contains('addPostFrameCallback'),
        isFalse,
        reason:
            'BUG DETECTED: ProfileScreen still schedules navigation during '
            'build. Protected-route redirection should happen in the router '
            'guard layer instead.',
      );

      expect(
        profileSource.contains('context.go(AppRoutes.login)'),
        isFalse,
        reason:
            'BUG DETECTED: ProfileScreen still performs login redirect itself. '
            'Protected-route redirection should happen in the router guard '
            'layer instead.',
      );
    });
  });
}
