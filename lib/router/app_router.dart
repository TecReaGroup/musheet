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
import '../screens/team_score_viewer_screen.dart';
import '../screens/team_setlist_detail_screen.dart';
import '../screens/settings/instrument_preference_screen.dart';
import '../screens/settings/cloud_sync_screen.dart';
import '../screens/settings/bluetooth_devices_screen.dart';
import '../screens/settings/notifications_screen.dart';
import '../screens/settings/help_support_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/login_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../models/score.dart';
import '../models/setlist.dart';
import '../models/team.dart';
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
  static const String teamScoreViewer = '/team-score-viewer';
  static const String teamSetlistDetail = '/team-setlist-detail';
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
      // Full screen routes (outside shell)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.scoreViewer,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          
          // Handle potential serialization: convert Map to Score if needed
          final score = extra['score'] is Score
              ? extra['score'] as Score
              : Score.fromJson(extra['score'] as Map<String, dynamic>);
          
          final instrumentScore = extra['instrumentScore'] == null
              ? null
              : (extra['instrumentScore'] is InstrumentScore
                  ? extra['instrumentScore'] as InstrumentScore
                  : InstrumentScore.fromJson(extra['instrumentScore'] as Map<String, dynamic>));
          
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
              score: score,
              instrumentScore: instrumentScore,
              setlistScores: setlistScores,
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
          // Handle potential serialization: convert Map to Score if needed
          final score = state.extra is Score
              ? state.extra as Score
              : Score.fromJson(state.extra as Map<String, dynamic>);
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
          // Handle potential serialization: convert Map to Setlist if needed
          final setlist = state.extra is Setlist
              ? state.extra as Setlist
              : Setlist.fromJson(state.extra as Map<String, dynamic>);
          return MaterialPage(
            key: state.pageKey,
            child: SetlistDetailScreen(setlist: setlist),
          );
        },
      ),
      // Team Score Viewer Route
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.teamScoreViewer,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          final teamScore = extra['teamScore'] is TeamScore
              ? extra['teamScore'] as TeamScore
              : TeamScore.fromJson(extra['teamScore'] as Map<String, dynamic>);

          final instrumentScore = extra['instrumentScore'] == null
              ? null
              : (extra['instrumentScore'] is TeamInstrumentScore
                  ? extra['instrumentScore'] as TeamInstrumentScore
                  : TeamInstrumentScore.fromJson(extra['instrumentScore'] as Map<String, dynamic>));

          final setlistScores = extra['setlistScores'] == null
              ? null
              : (extra['setlistScores'] as List).map((item) {
                  return item is TeamScore
                      ? item
                      : TeamScore.fromJson(item as Map<String, dynamic>);
                }).toList();

          return MaterialPage(
            key: state.pageKey,
            child: TeamScoreViewerScreen(
              teamScore: teamScore,
              instrumentScore: instrumentScore,
              setlistScores: setlistScores,
              currentIndex: extra['currentIndex'] as int?,
              setlistName: extra['setlistName'] as String?,
            ),
          );
        },
      ),
      // Team Setlist Detail Route
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.teamSetlistDetail,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          final setlist = extra['setlist'] is TeamSetlist
              ? extra['setlist'] as TeamSetlist
              : TeamSetlist.fromJson(extra['setlist'] as Map<String, dynamic>);

          final teamServerId = extra['teamServerId'] as int;

          return MaterialPage(
            key: state.pageKey,
            child: TeamSetlistDetailScreen(
              setlist: setlist,
              teamServerId: teamServerId,
            ),
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

  // Team navigation methods
  static void navigateToTeamScoreViewer(
    BuildContext context, {
    required TeamScore teamScore,
    TeamInstrumentScore? instrumentScore,
    List<TeamScore>? setlistScores,
    int? currentIndex,
    String? setlistName,
  }) {
    context.push(
      AppRoutes.teamScoreViewer,
      extra: {
        'teamScore': teamScore,
        'instrumentScore': instrumentScore,
        'setlistScores': setlistScores,
        'currentIndex': currentIndex,
        'setlistName': setlistName,
      },
    );
  }

  static void navigateToTeamSetlistDetail(
    BuildContext context,
    TeamSetlist setlist, {
    required int teamServerId,
  }) {
    context.push(
      AppRoutes.teamSetlistDetail,
      extra: {
        'setlist': setlist,
        'teamServerId': teamServerId,
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