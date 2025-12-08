import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/team_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/icon_mappings.dart';

enum AppPage { home, library, team, settings }

class CurrentPageNotifier extends Notifier<AppPage> {
  @override
  AppPage build() => AppPage.home;
  
  @override
  set state(AppPage newState) => super.state = newState;
}

final currentPageProvider = NotifierProvider<CurrentPageNotifier, AppPage>(CurrentPageNotifier.new);

// Notifier to signal search clear request
class ClearSearchRequestNotifier extends Notifier<int> {
  @override
  int build() => 0;
  
  void trigger() => state++;
}

final clearSearchRequestProvider = NotifierProvider<ClearSearchRequestNotifier, int>(ClearSearchRequestNotifier.new);

class MuSheetApp extends ConsumerWidget {
  const MuSheetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MuSheet',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  bool _isSnackBarVisible = false;

  Future<bool> _onWillPop() async {
    final searchQuery = ref.read(searchQueryProvider);
    
    // If search is active, clear search and return to home
    if (searchQuery.isNotEmpty) {
      ref.read(searchQueryProvider.notifier).state = '';
      ref.read(clearSearchRequestProvider.notifier).trigger();
      ref.read(currentPageProvider.notifier).state = AppPage.home;
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
    final currentPage = ref.watch(currentPageProvider);
    final teamEnabled = ref.watch(teamEnabledProvider);

    // If team is disabled and current page is team, redirect to settings
    if (!teamEnabled && currentPage == AppPage.team) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(currentPageProvider.notifier).state = AppPage.settings;
        }
      });
    }

    // Calculate the actual index for IndexedStack
    final int stackIndex;
    if (teamEnabled) {
      stackIndex = currentPage.index;
    } else {
      // When team is disabled: Home=0, Library=1, Settings=2
      switch (currentPage) {
        case AppPage.home:
          stackIndex = 0;
        case AppPage.library:
          stackIndex = 1;
        case AppPage.team:
          stackIndex = 2; // Will be redirected to settings
        case AppPage.settings:
          stackIndex = 2;
      }
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
      child: Scaffold(
        // Extend content to bottom system navigation bar area
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: IndexedStack(
          index: stackIndex,
          children: [
            const HomeScreen(),
            const LibraryScreen(),
            if (teamEnabled) const TeamScreen(),
            const SettingsScreen(),
          ],
        ),
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
                ref.read(currentPageProvider.notifier).state = _getPageFromIndex(index, teamEnabled);
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
}