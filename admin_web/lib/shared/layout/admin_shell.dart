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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(adminAuthProvider);

    return Scaffold(
      backgroundColor: AppColors.slate900,
      body: Row(
        children: [
          // Sidebar
          _AdminSidebar(
            currentPath: GoRouterState.of(context).matchedLocation,
            displayName: authState.displayName ?? authState.username,
          ),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final String currentPath;
  final String? displayName;

  const _AdminSidebar({
    required this.currentPath,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.slate800,
      child: Column(
        children: [
          // Logo Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.indigo500, AppColors.indigo600],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.indigo500.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.music,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MuSheet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Admin Console',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: AppColors.slate700, height: 1),

          // Navigation Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                children: [
                  _NavItem(
                    icon: LucideIcons.layoutDashboard,
                    label: 'Dashboard',
                    path: '/dashboard',
                    currentPath: currentPath,
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: LucideIcons.users,
                    label: 'Users',
                    path: '/users',
                    currentPath: currentPath,
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: LucideIcons.usersRound,
                    label: 'Teams',
                    path: '/teams',
                    currentPath: currentPath,
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: LucideIcons.settings,
                    label: 'Settings',
                    path: '/settings',
                    currentPath: currentPath,
                  ),
                ],
              ),
            ),
          ),

          // User Info Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.slate700),
              ),
            ),
            child: Row(
              children: [
                AdminUserAvatar(
                  name: displayName,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName ?? 'Admin',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Administrator',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final String currentPath;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
  });

  bool get isActive => currentPath == path;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(path),
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.slate700,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.indigo600 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : AppColors.gray400,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  color: isActive ? Colors.white : AppColors.gray300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
