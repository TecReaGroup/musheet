import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/team_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/score_viewer_screen.dart';
import '../screens/score_detail_screen.dart';
import '../screens/setlist_detail_screen.dart';
import '../screens/settings/instrument_preference_screen.dart';
import '../screens/settings/cloud_sync_screen.dart';
import '../screens/settings/bluetooth_devices_screen.dart';
import '../screens/settings/notifications_screen.dart';
import '../screens/settings/help_support_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/login_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../models/team.dart';
import '../core/data/data_scope.dart';
import '../app.dart';

// Route paths
class AppRoutes {
  static const String home = '/';
  static const String library = '/library';
  static const String team = '/team';
  static const String settings = '/settings';

  // Unified routes (scope passed via extra)
  static const String scoreViewer = '/score-viewer';
  static const String scoreDetail = '/score-detail';
  static const String setlistDetail = '/setlist-detail';

  // Settings sub-routes
  static const String instrumentPreference = '/instrument-preference';
  static const String cloudSync = '/cloud-sync';
  static const String bluetoothDevices = '/bluetooth-devices';
  static const String notifications = '/notifications';
  static const String helpSupport = '/help-support';
  static const String about = '/about';
  static const String login = '/login';
  static const String profile = '/profile';
}

// Shell route key for the main scaffold with bottom navigation
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// Provider for the GoRouter instance
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: kDebugMode,
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.library,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const LibraryScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.team,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const TeamScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.instrumentPreference,
            pageBuilder: (context, state) => const MaterialPage(
              child: InstrumentPreferenceScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.cloudSync,
            pageBuilder: (context, state) => const MaterialPage(
              child: CloudSyncScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.bluetoothDevices,
            pageBuilder: (context, state) => const MaterialPage(
              child: BluetoothDevicesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (context, state) => const MaterialPage(
              child: NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.helpSupport,
            pageBuilder: (context, state) => const MaterialPage(
              child: HelpSupportScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.about,
            pageBuilder: (context, state) => const MaterialPage(
              child: AboutScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.login,
            pageBuilder: (context, state) => const MaterialPage(
              child: LoginScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => const MaterialPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      // ========================================================================
      // Unified Full Screen Routes (outside shell)
      // ========================================================================

      // Unified Score Viewer - supports both Library and Team via DataScope
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.scoreViewer,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          // Parse DataScope
          final scope = extra['scope'] is DataScope
              ? extra['scope'] as DataScope
              : DataScope.fromJson(extra['scope'] as Map<String, dynamic>);

          // Parse Score
          final score = extra['score'] is Score
              ? extra['score'] as Score
              : Score.fromJson(extra['score'] as Map<String, dynamic>);

          // Parse optional InstrumentScore
          final instrumentScore = extra['instrumentScore'] == null
              ? null
              : (extra['instrumentScore'] is InstrumentScore
                  ? extra['instrumentScore'] as InstrumentScore
                  : InstrumentScore.fromJson(
                      extra['instrumentScore'] as Map<String, dynamic>));

          // Parse optional setlistScores
          final setlistScores = extra['setlistScores'] == null
              ? null
              : (extra['setlistScores'] as List).map((item) {
                  return item is Score
                      ? item
                      : Score.fromJson(item as Map<String, dynamic>);
                }).toList();

          return MaterialPage(
            key: state.pageKey,
            child: ScoreViewerScreen(
              scope: scope,
              score: score,
              instrumentScore: instrumentScore,
              setlistScores: setlistScores,
              currentIndex: extra['currentIndex'] as int?,
              setlistName: extra['setlistName'] as String?,
            ),
          );
        },
      ),

      // Unified Score Detail - supports both Library and Team via DataScope
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.scoreDetail,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          // Parse DataScope
          final scope = extra['scope'] is DataScope
              ? extra['scope'] as DataScope
              : DataScope.fromJson(extra['scope'] as Map<String, dynamic>);

          // Parse Score
          final score = extra['score'] is Score
              ? extra['score'] as Score
              : Score.fromJson(extra['score'] as Map<String, dynamic>);

          return MaterialPage(
            key: state.pageKey,
            child: ScoreDetailScreen(scope: scope, score: score),
          );
        },
      ),

      // Unified Setlist Detail - supports both Library and Team via DataScope
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.setlistDetail,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return MaterialPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Error: No setlist data provided')),
              ),
            );
          }

          // Parse DataScope
          final scope = extra['scope'] is DataScope
              ? extra['scope'] as DataScope
              : DataScope.fromJson(extra['scope'] as Map<String, dynamic>);

          // Parse Setlist
          final setlist = extra['setlist'] is Setlist
              ? extra['setlist'] as Setlist
              : Setlist.fromJson(extra['setlist'] as Map<String, dynamic>);

          return MaterialPage(
            key: state.pageKey,
            child: SetlistDetailScreen(scope: scope, setlist: setlist),
          );
        },
      ),
    ],
  );
});

// ============================================================================
// Navigation Helpers
// ============================================================================

class AppNavigation {
  static void navigateToHome(BuildContext context) {
    context.go(AppRoutes.home);
  }

  static void navigateToLibrary(BuildContext context) {
    context.go(AppRoutes.library);
  }

  static void navigateToTeam(BuildContext context) {
    context.go(AppRoutes.team);
  }

  static void navigateToSettings(BuildContext context) {
    context.go(AppRoutes.settings);
  }

  // ========================================================================
  // Unified Navigation Methods (using DataScope)
  // ========================================================================

  /// Navigate to score viewer (unified for Library and Team)
  static void navigateToScoreViewer(
    BuildContext context, {
    required DataScope scope,
    required Score score,
    InstrumentScore? instrumentScore,
    List<Score>? setlistScores,
    int? currentIndex,
    String? setlistName,
  }) {
    context.push(
      AppRoutes.scoreViewer,
      extra: {
        'scope': scope,
        'score': score,
        'instrumentScore': instrumentScore,
        'setlistScores': setlistScores,
        'currentIndex': currentIndex,
        'setlistName': setlistName,
      },
    );
  }

  /// Navigate to score detail (unified for Library and Team)
  static void navigateToScoreDetail(
    BuildContext context, {
    required DataScope scope,
    required Score score,
  }) {
    context.push(
      AppRoutes.scoreDetail,
      extra: {
        'scope': scope,
        'score': score,
      },
    );
  }

  /// Navigate to setlist detail (unified for Library and Team)
  static void navigateToSetlistDetail(
    BuildContext context, {
    required DataScope scope,
    required Setlist setlist,
  }) {
    context.push(
      AppRoutes.setlistDetail,
      extra: {
        'scope': scope,
        'setlist': setlist,
      },
    );
  }

  static void navigateToInstrumentPreference(BuildContext context) {
    context.go(AppRoutes.instrumentPreference);
  }

  // Get current route location
  static String getCurrentLocation(BuildContext context) {
    final router = GoRouter.of(context);
    return router.routerDelegate.currentConfiguration.uri.path;
  }

  // Check if we're on a specific route
  static bool isOnRoute(BuildContext context, String route) {
    return getCurrentLocation(context) == route;
  }
}
