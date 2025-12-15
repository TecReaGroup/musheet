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
import '../screens/instrument_preference_screen.dart';
import '../models/score.dart';
import '../models/setlist.dart';
import '../app.dart';

// Route paths
class AppRoutes {
  static const String home = '/';
  static const String library = '/library';
  static const String team = '/team';
  static const String settings = '/settings';
  static const String scoreViewer = '/score-viewer';
  static const String scoreDetail = '/score-detail';
  static const String setlistDetail = '/setlist-detail';
  static const String instrumentPreference = '/instrument-preference';
}

// Shell route key for the main scaffold with bottom navigation
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// Provider for the GoRouter instance
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
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
        ],
      ),
      // Full screen routes (outside shell)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.scoreViewer,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return MaterialPage(
            key: state.pageKey,
            child: ScoreViewerScreen(
              score: extra['score'] as Score,
              instrumentScore: extra['instrumentScore'] as InstrumentScore?,
              setlistScores: extra['setlistScores'] as List<Score>?,
              currentIndex: extra['currentIndex'] as int?,
              setlistName: extra['setlistName'] as String?,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.scoreDetail,
        pageBuilder: (context, state) {
          final score = state.extra as Score;
          return MaterialPage(
            key: state.pageKey,
            child: ScoreDetailScreen(score: score),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.setlistDetail,
        pageBuilder: (context, state) {
          final setlist = state.extra as Setlist;
          return MaterialPage(
            key: state.pageKey,
            child: SetlistDetailScreen(setlist: setlist),
          );
        },
      ),
    ],
  );
});

// Navigation helper for bottom navigation bar
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

  static void navigateToScoreViewer(
    BuildContext context, {
    required Score score,
    InstrumentScore? instrumentScore,
    List<Score>? setlistScores,
    int? currentIndex,
    String? setlistName,
  }) {
    context.push(
      AppRoutes.scoreViewer,
      extra: {
        'score': score,
        'instrumentScore': instrumentScore,
        'setlistScores': setlistScores,
        'currentIndex': currentIndex,
        'setlistName': setlistName,
      },
    );
  }

  static void navigateToScoreDetail(BuildContext context, Score score) {
    context.push(AppRoutes.scoreDetail, extra: score);
  }

  static void navigateToSetlistDetail(BuildContext context, Setlist setlist) {
    context.push(AppRoutes.setlistDetail, extra: setlist);
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