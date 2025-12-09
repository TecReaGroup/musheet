import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/library_screen.dart';
import 'screens/home_screen.dart';
import 'utils/icon_mappings.dart';
import 'router/app_router.dart';

enum AppPage { home, library, team, settings }

// Notifier to signal search clear request
class ClearSearchRequestNotifier extends Notifier<int> {
  @override
  int build() => 0;
  
  void trigger() => state++;
}

final clearSearchRequestProvider = NotifierProvider<ClearSearchRequestNotifier, int>(ClearSearchRequestNotifier.new);

// Provider to store shared file path from sharing intent
class SharedFilePathNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setPath(String? path) => state = path;
  void clear() => state = null;
}

final sharedFilePathProvider = NotifierProvider<SharedFilePathNotifier, String?>(SharedFilePathNotifier.new);

class MuSheetApp extends ConsumerWidget {
  const MuSheetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    
    return MaterialApp.router(
      title: 'MuSheet',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
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
      ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
        if (value.isNotEmpty && mounted) {
          _handleSharedFiles(value);
        }
      }).catchError((e) {
        debugPrint('Error getting initial media: $e');
      });
    });

    // Handle shared files when app is already running
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty && mounted) {
          _handleSharedFiles(value);
        }
      },
      onError: (err) {
        debugPrint('Error receiving shared files: $err');
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
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);

    if (isPdf || isImage) {
      try {
        // Copy shared file to app's documents directory to ensure it's accessible
        final sourceFile = File(filePath);
        if (!await sourceFile.exists()) {
          debugPrint('Shared file does not exist: $filePath');
          return;
        }

        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = filePath.split('/').last.split('\\').last;
        final destPath = '${directory.path}${Platform.pathSeparator}shared_${timestamp}_$fileName';

        // Copy file to app directory
        await sourceFile.copy(destPath);

        // Navigate to Library page and show add score modal
        if (mounted) {
          // Navigate to library using go_router
          context.go(AppRoutes.library);

          // Switch to Scores tab
          ref.read(libraryTabProvider.notifier).state = LibraryTab.scores;

          // Set shared file path and trigger modal in LibraryScreen
          ref.read(sharedFilePathProvider.notifier).setPath(destPath);
          ref.read(showCreateScoreModalProvider.notifier).state = true;
        }
      } catch (e) {
        debugPrint('Error handling shared file: $e');
      }
    }

    // Clear the intent to prevent re-processing
    ReceiveSharingIntent.instance.reset();
  }

  Future<bool> _onWillPop() async {
    final searchQuery = ref.read(searchQueryProvider);
    
    // If search is active, clear search and return to home
    if (searchQuery.isNotEmpty) {
      ref.read(searchQueryProvider.notifier).state = '';
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
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Press back again to exit',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: AppColors.gray700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.only(
          bottom: 12,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 1),
      ),
    ).closed.then((_) {
      _isSnackBarVisible = false;
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final teamEnabled = ref.watch(teamEnabledProvider);
    final currentLocation = GoRouterState.of(context).uri.path;
    
    // Determine current page from location
    AppPage currentPage = _getPageFromLocation(currentLocation);

    // If team is disabled and current page is team, redirect to settings
    if (!teamEnabled && currentPage == AppPage.team) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(AppRoutes.settings);
        }
      });
    }

    // Ensure system UI style is applied on every build
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ));

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
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
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