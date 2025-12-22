import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mappings.dart';
import '../widgets/common_widgets.dart';
import '../models/instrument_score.dart';
import '../providers/auth_provider.dart';
import 'library_screen.dart' show preferredInstrumentProvider, teamEnabledProvider;
import '../router/app_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _navigateToLogin(BuildContext context) {
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authData = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Fixed header
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.gray200)),
            ),
            // Add top safe area padding
            padding: EdgeInsets.fromLTRB(16, 16 + MediaQuery.of(context).padding.top, 16, 24),
            child: const Row(
              children: [
                Text(
                  'Settings',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.gray700),
                ),
              ],
            ),
          ),
          // Scrollable content
          Expanded(
            child: ListView(
              // Add bottom padding for bottom navigation bar
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
              children: [
          // Profile card section - shows login button or user profile
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    if (authData.isAuthenticated) {
                      // Show user profile options
                      _showUserProfileSheet(context, ref, authData);
                    } else {
                      // Navigate to login screen
                      _navigateToLogin(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: authData.isAuthenticated
                      ? _buildLoggedInProfile(authData)
                      : _buildLoginPrompt(),
                  ),
                ),
              ),
            ),
          ),

          SettingsGroup(
            title: 'PREFERENCES',
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final preferredInstrument = ref.watch(preferredInstrumentProvider);
                  String displayText = 'Not set';
                  if (preferredInstrument != null) {
                    // Try to find the instrument type
                    final instrumentType = InstrumentType.values.firstWhere(
                      (type) => type.name == preferredInstrument,
                      orElse: () => InstrumentType.other,
                    );
                    displayText = instrumentType.name[0].toUpperCase() + instrumentType.name.substring(1);
                  }
                  
                  return SettingsListItem(
                    icon: AppIcons.piano,
                    label: 'Preferred Instrument',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.gray500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(AppIcons.chevronRight, size: 20, color: AppColors.gray400),
                      ],
                    ),
                    onTap: () {
                      AppNavigation.navigateToInstrumentPreference(context);
                    },
                    showDivider: true,
                    isFirst: true,
                  );
                },
              ),
              Consumer(
                builder: (context, ref, child) {
                  final teamEnabled = ref.watch(teamEnabledProvider);
                  
                  return SettingsListItem(
                    icon: AppIcons.people,
                    label: 'Enable Team',
                    trailing: GestureDetector(
                      onTap: () {
                        ref.read(teamEnabledProvider.notifier).setTeamEnabled(!teamEnabled);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: teamEnabled ? AppColors.blue500 : AppColors.gray300,
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: teamEnabled ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      ref.read(teamEnabledProvider.notifier).setTeamEnabled(!teamEnabled);
                    },
                    showDivider: true,
                  );
                },
              ),
              SettingsListItem(
                icon: AppIcons.bluetooth,
                label: 'Bluetooth Devices',
                onTap: () => context.go(AppRoutes.bluetoothDevices),
                isLast: true,
              ),
            ],
          ),

          SettingsGroup(
            title: 'SYNC & STORAGE',
            children: [
              SettingsListItem(
                icon: AppIcons.cloud,
                label: 'Cloud Sync',
                onTap: () => context.go(AppRoutes.cloudSync),
                showDivider: true,
                isFirst: true,
              ),
              SettingsListItem(
                icon: AppIcons.notifications,
                label: 'Notifications',
                onTap: () => context.go(AppRoutes.notifications),
                isLast: true,
              ),
            ],
          ),

          SettingsGroup(
            title: 'ABOUT',
            children: [
              SettingsListItem(
                icon: AppIcons.helpOutline,
                label: 'Help & Support',
                onTap: () => context.go(AppRoutes.helpSupport),
                showDivider: true,
                isFirst: true,
              ),
              SettingsListItem(
                icon: AppIcons.infoOutline,
                label: 'About MuSheet',
                onTap: () => context.go(AppRoutes.about),
                isLast: true,
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Text('MuSheet', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                SizedBox(height: 8),
                Text(
                  'Digital score management for musicians',
                  style: TextStyle(fontSize: 12, color: AppColors.gray400),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(32),
          ),
          child: const Center(
            child: Icon(AppIcons.person, color: AppColors.gray400, size: 32),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sign in to sync',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect to server to sync your music',
                style: TextStyle(fontSize: 14, color: AppColors.gray500),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.blue500,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Login',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedInProfile(AuthData authData) {
    final user = authData.user;
    final displayName = user?.displayName ?? 'User';
    final username = user?.username ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.blue500, Color(0xFF9333EA)]),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 4),
              Text(username, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: authData.isConnected ? AppColors.emerald500 : AppColors.gray400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    authData.isConnected ? 'Connected' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: authData.isConnected ? AppColors.emerald600 : AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Icon(AppIcons.chevronRight, color: AppColors.gray400),
      ],
    );
  }

  /// Show sign out confirmation dialog with pending changes warning
  /// Per APP_SYNC_LOGIC.md §1.5.3: Check for unsynced data before logout
  Future<void> _showSignOutConfirmation(BuildContext context, WidgetRef ref) async {
    // Check for pending changes
    final pendingCount = await ref.read(authProvider.notifier).getPendingChangesCount();

    if (!context.mounted) return;

    if (pendingCount > 0) {
      // Show warning dialog with pending changes count
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsynced Data'),
          content: Text(
            'You have $pendingCount unsynced changes that will be lost if you sign out.\n\n'
            'Are you sure you want to sign out?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.red500),
              child: const Text('Sign Out Anyway'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;
    } else {
      // No pending changes, just confirm
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'All local data will be deleted. Are you sure you want to sign out?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.red500),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;
    }

    // Perform logout
    await ref.read(authProvider.notifier).logout();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully')),
      );
    }
  }

  void _showUserProfileSheet(BuildContext context, WidgetRef ref, AuthData authData) {
    final parentContext = context; // Save parent context for use after bottom sheet closes
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(AppIcons.refreshCw),
              title: const Text('Sync Now'),
              onTap: () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('Syncing...')),
                );
              },
            ),
            ListTile(
              leading: Icon(AppIcons.cloud, color: AppColors.gray600),
              title: const Text('Cloud Sync Settings'),
              onTap: () {
                Navigator.pop(sheetContext);
                parentContext.go(AppRoutes.cloudSync);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(AppIcons.close, color: AppColors.red500),
              title: Text('Sign Out', style: TextStyle(color: AppColors.red500)),
              onTap: () {
                Navigator.pop(sheetContext);
                // Use parent context which remains valid after bottom sheet closes
                _showSignOutConfirmation(parentContext, ref);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}