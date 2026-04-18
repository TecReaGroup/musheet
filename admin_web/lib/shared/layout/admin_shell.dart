import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/admin_widgets.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  static const _destinations = [
    AdminNavDestination(
      icon: LucideIcons.layoutDashboard,
      label: 'Dashboard',
      path: '/dashboard',
    ),
    AdminNavDestination(
      icon: LucideIcons.users,
      label: 'Users',
      path: '/users',
    ),
    AdminNavDestination(
      icon: LucideIcons.usersRound,
      label: 'Teams',
      path: '/teams',
    ),
    AdminNavDestination(
      icon: LucideIcons.settings2,
      label: 'Settings',
      path: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(adminAuthProvider);
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1100;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AdminSidebar(
                  compact: compact,
                  currentPath: currentPath,
                  displayName: authState.displayName ?? authState.username,
                  userId: authState.userId,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 20, 20, 20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.white.withValues(alpha: 0.66),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: child,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final bool compact;
  final String currentPath;
  final String? displayName;
  final int? userId;

  const _AdminSidebar({
    required this.compact,
    required this.currentPath,
    this.displayName,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final width = compact ? 240.0 : 288.0;

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      child: AdminSurface(
        padding: const EdgeInsets.all(20),
        radius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminAppWordmark(),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEFF6FF), Color(0xFFECFDF5)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.blue100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const MuSheetBrandMark(
                        size: 40,
                        radius: 14,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Workspace',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: AppColors.gray900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Users, teams, settings, and platform health',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.gray600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.shieldCheck,
                      size: 18,
                      color: AppColors.blue600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Platform-level actions are grouped here to keep the main content area focused.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.gray600,
                            height: 1.45,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Navigation',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.gray500,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: AdminSidebarNav(
                  destinations: AdminShell._destinations,
                  currentPath: currentPath,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Row(
                children: [
                  AdminUserAvatar(name: displayName, userId: userId, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName ?? 'Administrator',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: AppColors.gray900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'System administrator',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
