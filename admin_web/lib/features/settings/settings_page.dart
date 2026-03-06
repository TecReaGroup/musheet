import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/admin_api_client.dart';
import '../../core/providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/admin_widgets.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isCheckingHealth = false;
  bool? _isHealthy;
  String? _healthError;

  Future<void> _checkHealth() async {
    setState(() {
      _isCheckingHealth = true;
      _isHealthy = null;
      _healthError = null;
    });

    final result = await AdminApiClient.instance.checkHealth();

    if (mounted) {
      setState(() {
        _isCheckingHealth = false;
        _isHealthy = result.isSuccess;
        _healthError = result.error;
      });

      if (result.isSuccess) {
        AdminToast.success(context, 'Server is healthy');
      } else {
        AdminToast.error(context, 'Server health check failed');
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
    );

    if (confirmed && mounted) {
      await ref.read(adminAuthProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthProvider);

    return Scaffold(
      backgroundColor: AppColors.slate900,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'System Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage system configuration and settings',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: 32),

            // Account Section
            _SettingsSection(
              title: 'ACCOUNT',
              children: [
                _SettingsTile(
                  icon: LucideIcons.user,
                  title: 'Current Admin',
                  subtitle: authState.displayName ?? authState.username ?? 'Unknown',
                  trailing: AdminUserAvatar(
                    name: authState.displayName ?? authState.username,
                    size: 36,
                  ),
                ),
                _SettingsTile(
                  icon: LucideIcons.logOut,
                  title: 'Logout',
                  subtitle: 'Sign out of admin console',
                  onTap: _handleLogout,
                  trailing: const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // System Section
            _SettingsSection(
              title: 'SYSTEM',
              children: [
                _SettingsTile(
                  icon: LucideIcons.activity,
                  title: 'Server Health',
                  subtitle: _isHealthy == null
                      ? 'Check server status'
                      : _isHealthy!
                          ? 'Server is healthy'
                          : _healthError ?? 'Server is unhealthy',
                  onTap: _isCheckingHealth ? null : _checkHealth,
                  trailing: _isCheckingHealth
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _isHealthy == null
                          ? const Icon(
                              LucideIcons.chevronRight,
                              size: 18,
                              color: AppColors.gray400,
                            )
                          : Icon(
                              _isHealthy!
                                  ? LucideIcons.circleCheck
                                  : LucideIcons.circleAlert,
                              size: 20,
                              color: _isHealthy!
                                  ? AppColors.emerald500
                                  : AppColors.red500,
                            ),
                ),
                _SettingsTile(
                  icon: LucideIcons.server,
                  title: 'API Endpoint',
                  subtitle: AdminApiClient.instance.baseUrl,
                  trailing: const Icon(
                    LucideIcons.externalLink,
                    size: 18,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Coming Soon Section
            _SettingsSection(
              title: 'CONFIGURATION (COMING SOON)',
              children: [
                _SettingsTile(
                  icon: LucideIcons.userPlus,
                  title: 'Registration Control',
                  subtitle: 'Enable or disable new user registration',
                  enabled: false,
                  trailing: Switch(
                    value: true,
                    onChanged: null,
                  ),
                ),
                _SettingsTile(
                  icon: LucideIcons.database,
                  title: 'Storage Quotas',
                  subtitle: 'Set storage limits for users and teams',
                  enabled: false,
                  trailing: const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.gray300,
                  ),
                ),
                _SettingsTile(
                  icon: LucideIcons.fileText,
                  title: 'Audit Logs',
                  subtitle: 'View system operation logs',
                  enabled: false,
                  trailing: const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.gray300,
                  ),
                ),
                _SettingsTile(
                  icon: LucideIcons.download,
                  title: 'Data Export',
                  subtitle: 'Export users, teams, and logs',
                  enabled: false,
                  trailing: const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.gray300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // About Section
            _SettingsSection(
              title: 'ABOUT',
              children: [
                const _SettingsTile(
                  icon: LucideIcons.info,
                  title: 'MuSheet Admin',
                  subtitle: 'Version 1.0.0',
                ),
                const _SettingsTile(
                  icon: LucideIcons.code,
                  title: 'Built with',
                  subtitle: 'Flutter Web + Riverpod + Serverpod',
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Settings Section
// ============================================================================

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gray500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.slate800,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate700),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(height: 1, indent: 56, color: AppColors.slate700),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Settings Tile
// ============================================================================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        hoverColor: AppColors.slate700,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.slate700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.gray400),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
