import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'utils/icon_mappings.dart';
import 'router/app_router.dart';
import 'providers/app_bootstrap_provider.dart';
import 'providers/core_providers.dart';
import 'providers/auth_state_provider.dart';
import 'providers/ui_state_providers.dart';
import 'utils/logger.dart';
import 'widgets/common_widgets.dart';

enum AppPage { home, library, team, settings }

class MuSheetApp extends ConsumerStatefulWidget {
  const MuSheetApp({super.key});

  static const _systemUiStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  @override
  ConsumerState<MuSheetApp> createState() => _MuSheetAppState();
}

class _MuSheetAppState extends ConsumerState<MuSheetApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(appBootstrapProvider.notifier).ensureStarted();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapState = ref.watch(appBootstrapProvider);

    if (bootstrapState.isBootstrapping) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: MuSheetApp._systemUiStyle,
        child: MaterialApp(
          title: 'MuSheet',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        ),
      );
    }

    if (bootstrapState.hasError) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: MuSheetApp._systemUiStyle,
        child: MaterialApp(
          title: 'MuSheet',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: ErrorScreen(error: bootstrapState.error.toString()),
        ),
      );
    }

    final router = ref.watch(goRouterProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: MuSheetApp._systemUiStyle,
      child: MaterialApp.router(
        title: 'MuSheet',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }
}

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  bool _isSnackBarVisible = false;
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initSharingIntent();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  void _initSharingIntent() {
    // Delay initial media check to ensure app is fully initialized
    // This prevents UI freeze when app is launched via share intent
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Handle shared files when app is opened from sharing
      ReceiveSharingIntent.instance
          .getInitialMedia()
          .then((List<SharedMediaFile> value) {
            if (value.isNotEmpty && mounted) {
              _handleSharedFiles(value);
            }
          })
          .catchError((e) {
            Log.e('SHARE', 'Error getting initial media', error: e);
          });
    });

    // Handle shared files when app is already running
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            if (value.isNotEmpty && mounted) {
              _handleSharedFiles(value);
            }
          },
          onError: (err) {
            Log.e('SHARE', 'Error receiving shared files', error: err);
          },
        );
  }

  Future<void> _handleSharedFiles(List<SharedMediaFile> sharedFiles) async {
    // Only handle the first file for now
    final file = sharedFiles.first;
    final filePath = file.path;

    // Check if it's a PDF or image file
    final extension = filePath.split('.').last.toLowerCase();
    final isPdf = extension == 'pdf';
    final isImage = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
    ].contains(extension);

    if (isPdf || isImage) {
      try {
        // Copy shared file to app's documents directory to ensure it's accessible
        final sourceFile = File(filePath);
        if (!await sourceFile.exists()) {
          Log.w('SHARE', 'Shared file does not exist: $filePath');
          return;
        }

        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = filePath.split('/').last.split('\\').last;
        final destPath =
            '${directory.path}${Platform.pathSeparator}shared_${timestamp}_$fileName';

        // Copy file to app directory
        await sourceFile.copy(destPath);

        // Navigate to Library page and show add score modal
        if (mounted) {
          // Navigate to library using go_router
          context.go(AppRoutes.library);

          // Switch to Scores tab
          ref.read(libraryTabProvider.notifier).setTab(LibraryTab.scores);

          // Set shared file path and trigger modal in LibraryScreen
          ref.read(sharedFilePathProvider.notifier).setPath(destPath);
          ref.read(showCreateScoreModalProvider.notifier).show();
        }
      } catch (e) {
        Log.e('SHARE', 'Error handling shared file', error: e);
      }
    }

    // Clear the intent to prevent re-processing
    ReceiveSharingIntent.instance.reset();
  }

  Future<bool> _onWillPop() async {
    final searchQuery = ref.read(searchQueryProvider);

    // If search is active, clear search and return to home
    if (searchQuery.isNotEmpty) {
      ref.read(searchQueryProvider.notifier).clear();
      ref.read(clearSearchRequestProvider.notifier).trigger();
      context.go(AppRoutes.home);
      return false;
    }

    // Double back to exit - only exit if snackbar is currently visible
    if (_isSnackBarVisible) {
      return true;
    }

    // Show snackbar
    _isSnackBarVisible = true;
    AppToast.info(
      context,
      'Press back again to exit',
      duration: AppToast.shortDuration,
    ).closed.then((_) {
      _isSnackBarVisible = false;
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final libraryMode = ref.watch(libraryStorageModeProvider);
    final teamEnabled = ref.watch(teamEnabledProvider) &&
        authState.isAuthenticated &&
        libraryMode == LibraryStorageMode.account;
    final currentLocation = GoRouterState.of(context).uri.path;

    // Determine current page from location
    AppPage currentPage = _getPageFromLocation(currentLocation);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            // Extend content to bottom system navigation bar area
            extendBody: true,
            extendBodyBehindAppBar: true,
            body: widget.child,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                // Add white background to ensure bottom navigation bar is visible
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              // Add bottom safe area padding
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              child: Theme(
                // Disable ripple effect on bottom navigation bar
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  currentIndex: _getAdjustedIndex(currentPage, teamEnabled),
                  onTap: (index) {
                    final page = _getPageFromIndex(index, teamEnabled);
                    _navigateToPage(context, page);
                  },
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(AppIcons.homeOutlined),
                      activeIcon: Icon(AppIcons.home),
                      label: 'Home',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(AppIcons.libraryMusicOutlined),
                      activeIcon: Icon(AppIcons.libraryMusic),
                      label: 'Library',
                    ),
                    if (teamEnabled)
                      const BottomNavigationBarItem(
                        icon: Icon(AppIcons.peopleOutline),
                        activeIcon: Icon(AppIcons.people),
                        label: 'Team',
                      ),
                    const BottomNavigationBarItem(
                      icon: Icon(AppIcons.settingsOutlined),
                      activeIcon: Icon(AppIcons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to get adjusted index for bottom navigation
  int _getAdjustedIndex(AppPage page, bool teamEnabled) {
    if (teamEnabled) {
      return page.index;
    } else {
      // When team is disabled: Home=0, Library=1, Settings=2
      switch (page) {
        case AppPage.home:
          return 0;
        case AppPage.library:
          return 1;
        case AppPage.team:
          return 2; // Should not happen, but default to settings
        case AppPage.settings:
          return 2;
      }
    }
  }

  // Helper to get page from bottom navigation index
  AppPage _getPageFromIndex(int index, bool teamEnabled) {
    if (teamEnabled) {
      // Team enabled: Home=0, Library=1, Team=2, Settings=3
      return AppPage.values[index];
    } else {
      // Team disabled: Home=0, Library=1, Settings=2
      switch (index) {
        case 0:
          return AppPage.home;
        case 1:
          return AppPage.library;
        case 2:
          return AppPage.settings;
        default:
          return AppPage.home;
      }
    }
  }

  // Get page from current location
  AppPage _getPageFromLocation(String location) {
    switch (location) {
      case AppRoutes.home:
        return AppPage.home;
      case AppRoutes.library:
        return AppPage.library;
      case AppRoutes.team:
        return AppPage.team;
      case AppRoutes.settings:
        return AppPage.settings;
      default:
        return AppPage.home;
    }
  }

  // Navigate to page using go_router
  void _navigateToPage(BuildContext context, AppPage page) {
    switch (page) {
      case AppPage.home:
        context.go(AppRoutes.home);
        break;
      case AppPage.library:
        context.go(AppRoutes.library);
        break;
      case AppPage.team:
        context.go(AppRoutes.team);
        break;
      case AppPage.settings:
        context.go(AppRoutes.settings);
        break;
    }
  }
}
