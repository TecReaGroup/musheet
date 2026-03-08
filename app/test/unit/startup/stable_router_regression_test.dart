library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stable router regression', () {
    late String routerSource;
    late String appSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      routerSource = File('$projectRoot/lib/router/app_router.dart')
          .readAsStringSync();
      appSource = File('$projectRoot/lib/app.dart').readAsStringSync();
    });

    test('router must keep team route registered regardless of auth mode', () {
      expect(
        routerSource.contains('path: AppRoutes.team'),
        isTrue,
        reason: 'The router should always register the Team route.',
      );

      expect(
        routerSource.contains('if (libraryMode == LibraryStorageMode.account)'),
        isFalse,
        reason:
            'BUG DETECTED: The route table changes with auth/library mode. '
            'The Team route must stay registered and access should be controlled '
            'through redirect/gating instead of dynamically inserting routes.',
      );
    });

    test('router instance must stay stable across auth changes', () {
      expect(
        routerSource.contains('refreshListenable: refreshNotifier'),
        isTrue,
        reason:
            'BUG DETECTED: GoRouter should refresh via a listenable instead of '
            'being recreated when auth state changes.',
      );

      expect(
        routerSource.contains('final authState = ref.watch(authStateProvider);'),
        isFalse,
        reason:
            'BUG DETECTED: goRouterProvider still watches auth state directly, '
            'which recreates the router and navigator tree on login/logout.',
      );

      expect(
        routerSource.contains('final authState = ref.read(authStateProvider);'),
        isTrue,
        reason:
            'Router redirect should read the latest auth state without '
            'rebuilding the whole router instance.',
      );
    });

    test('main scaffold must not navigate during build for team gating', () {
      final buildStart = appSource.indexOf('Widget build(BuildContext context)');
      final helperStart = appSource.indexOf('// Helper to get adjusted index', buildStart);
      final buildBody = appSource.substring(buildStart, helperStart);

      expect(
        buildBody.contains('addPostFrameCallback'),
        isFalse,
        reason:
            'BUG DETECTED: MainScaffold performs post-frame navigation from build. '
            'Team gating must be handled by stable router redirect/gating, not by '
            'scheduling context.go() during widget build.',
      );

      expect(
        buildBody.contains('context.go(AppRoutes.settings)'),
        isFalse,
        reason:
            'BUG DETECTED: MainScaffold navigates away from Team inside build. '
            'This risks layout-time tree mutation and GlobalKey conflicts.',
      );
    });
  });
}
