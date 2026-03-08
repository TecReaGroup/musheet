import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mappings.dart';
import '../widgets/common_widgets.dart';
import '../widgets/user_avatar.dart';
import '../models/instrument_score.dart';
import '../providers/auth_state_provider.dart';
import '../providers/preferred_instrument_provider.dart';
import '../providers/ui_state_providers.dart' show teamEnabledProvider;
import '../router/app_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _navigateToLogin(BuildContext context) {
    context.go(AppRoutes.login);
  }

  Future<void> _showAccountMenu(BuildContext cardContext, AuthState authState) async {
    final navigator = Navigator.of(cardContext, rootNavigator: true);
    final overlay = navigator.overlay;
    final renderBox = cardContext.findRenderObject() as RenderBox?;

    if (overlay == null || renderBox == null) {
      return;
    }

    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final cardBottomRight = renderBox.localToGlobal(
      renderBox.size.bottomRight(Offset.zero),
      ancestor: overlayBox,
    );
    const horizontalMargin = 16.0;
    const verticalSpacing = -16.0;

    await showGeneralDialog<void>(
      context: cardContext,
      barrierLabel: 'Dismiss account menu',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: horizontalMargin,
                right: horizontalMargin,
                top: cardBottomRight.dy + verticalSpacing,
                child: Material(
                  color: Colors.transparent,
                  child: _buildAccountMenu(dialogContext, authState),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 180),
    );
  }

  Widget _buildAccountCard(BuildContext context, AuthState authState) {
    final isLoggedIn = authState.isAuthenticated;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Builder(
              builder: (cardContext) {
                return Material(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _showAccountMenu(cardContext, authState),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: _buildAccountSummary(authState),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(width: 1, height: 64, color: AppColors.gray200),
          Material(
            color: Colors.transparent,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                if (isLoggedIn) {
                  context.go(AppRoutes.profile);
                } else {
                  _navigateToLogin(context);
                }
              },
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: const SizedBox(
                width: 52,
                height: 88,
                child: Center(
                  child: Icon(AppIcons.chevronRight, color: AppColors.gray400),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSummary(AuthState authState) {
    final user = authState.user;
    final isLoggedIn = authState.isAuthenticated;
    final displayName = user?.displayName ?? 'Local Library';
    final subtitle = isLoggedIn
        ? (user?.username ?? 'Signed in account')
        : 'On this device';

    return Row(
      children: [
        isLoggedIn
            ? UserAvatar(
                userId: user?.id,
                avatarIdentifier: user?.avatarUrl,
                displayName: displayName,
                size: 56,
              )
            : Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Icon(AppIcons.libraryMusic, color: AppColors.gray500, size: 24),
                ),
              ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.gray700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.gray600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (isLoggedIn)
                ConnectionStatusIndicator.small(isConnected: authState.isConnected)
              else
                const Text(
                  'Sync off',
                  style: TextStyle(fontSize: 12, color: AppColors.gray500),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountMenu(BuildContext context, AuthState authState) {
    final isLoggedIn = authState.isAuthenticated;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: AppColors.gray200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            _AccountSwitcherTile(
              icon: AppIcons.libraryMusic,
              iconColor: !isLoggedIn ? AppColors.blue600 : AppColors.gray500,
              iconBackgroundColor: !isLoggedIn
                  ? AppColors.blue50
                  : AppColors.gray100,
              title: 'Local Library',
              subtitle: 'On this device',
              selected: !isLoggedIn,
              showDivider: true,
              onTap: () => Navigator.of(context).pop(),
            ),
            if (isLoggedIn)
              _AccountSwitcherTile(
                icon: AppIcons.person,
                iconColor: AppColors.blue600,
                iconBackgroundColor: AppColors.blue50,
                title: authState.user?.displayName ?? 'Signed-in Account',
                subtitle: authState.user?.username ?? 'Signed in',
                selected: true,
                showDivider: true,
                onTap: () => Navigator.of(context).pop(),
              ),
            _AccountAddTile(
              onTap: () {
                Navigator.of(context).pop();
                _navigateToLogin(context);
              },
            ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

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
                // Profile card section - local account summary + account actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildAccountCard(context, authState),
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
                        final canUseTeam = authState.isAuthenticated;
                        
                        return SettingsListItem(
                          icon: AppIcons.people,
                          label: 'Enable Team',
                          trailing: GestureDetector(
                            onTap: () {
                              if (!canUseTeam) return;
                              ref.read(teamEnabledProvider.notifier).setTeamEnabled(!teamEnabled);
                            },
                            child: Opacity(
                              opacity: canUseTeam ? 1 : 0.5,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: teamEnabled && canUseTeam
                                      ? AppColors.blue500
                                      : AppColors.gray300,
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: teamEnabled && canUseTeam
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
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
                          ),
                          onTap: () {
                            if (!canUseTeam) {
                              AppToast.info(
                                context,
                                'Sign in to enable Team features',
                              );
                              return;
                            }
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
}

class _AccountSwitcherTile extends StatelessWidget {
  const _AccountSwitcherTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
    this.showDivider = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool selected;
  final bool showDivider;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blue50 : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(bottom: BorderSide(color: AppColors.gray100))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: selected ? AppColors.blue600 : AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  AppIcons.check,
                  size: 18,
                  color: AppColors.blue600,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountAddTile extends StatelessWidget {
  const _AccountAddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  AppIcons.add,
                  size: 18,
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sign in with another account',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                AppIcons.chevronRight,
                size: 18,
                color: AppColors.gray400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}