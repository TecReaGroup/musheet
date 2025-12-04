import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
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

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);

    // Ensure system UI style is applied on every build
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ));

    return Scaffold(
      // Extend content to bottom system navigation bar area
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: IndexedStack(
        index: currentPage.index,
        children: const [
          HomeScreen(),
          LibraryScreen(),
          TeamScreen(),
          SettingsScreen(),
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
            currentIndex: currentPage.index,
            onTap: (index) {
              ref.read(currentPageProvider.notifier).state = AppPage.values[index];
            },
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(AppIcons.homeOutlined),
                activeIcon: Icon(AppIcons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.libraryMusicOutlined),
                activeIcon: Icon(AppIcons.libraryMusic),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.peopleOutline),
                activeIcon: Icon(AppIcons.people),
                label: 'Team',
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.settingsOutlined),
                activeIcon: Icon(AppIcons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}