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

    if (!mounted) return;

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

  Future<void> _handleLogout() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Logout',
      message: 'Sign out of the admin workspace on this device?',
      confirmLabel: 'Logout',
    );

    if (confirmed && mounted) {
      await ref.read(adminAuthProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthProvider);

    return AdminPageScaffold(
      eyebrow: 'Configuration',
      title: 'System settings',
      subtitle:
          'Review environment information, account access, and planned configuration capabilities in a layout consistent with the main app.',
      actions: [
        OutlinedButton.icon(
          onPressed: _isCheckingHealth ? null : _checkHealth,
          icon: _isCheckingHealth
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.activity, size: 18),
          label: const Text('Check health'),
        ),
        ElevatedButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(LucideIcons.logOut, size: 18),
          label: const Text('Logout'),
        ),
      ],
      hero: AdminInfoHero(
        icon: LucideIcons.settings,
        title: 'Environment overview',
        subtitle:
            'Keep account context, service health, and future platform controls in clearly separated groups so low-frequency configuration remains easy to scan.',
        trailing: [
          AdminMetricPill(
            icon: LucideIcons.user,
            label: 'Admin',
            value: authState.username ?? 'Unknown',
          ),
          AdminMetricPill(
            icon: LucideIcons.server,
            label: 'Health',
            value: _isHealthy == null
                ? 'Unchecked'
                : _isHealthy!
                    ? 'Healthy'
                    : 'Issue',
            accent: _isHealthy == null
                ? AppColors.blue600
                : _isHealthy!
                    ? AppColors.emerald600
                    : AppColors.red600,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 1120;

          final accountColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingsSection(
                title: 'Account',
                subtitle: 'Current administrator identity and session actions.',
                icon: LucideIcons.user,
                children: [
                  _SettingsTile(
                    icon: LucideIcons.user,
                    title: 'Current administrator',
                    subtitle:
                        authState.displayName ?? authState.username ?? 'Unknown user',
                    trailing: AdminUserAvatar(
                      name: authState.displayName ?? authState.username,
                      size: 40,
                    ),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.badgeInfo,
                    title: 'Username',
                    subtitle: authState.username ?? 'Unavailable',
                    trailing: const Icon(
                      LucideIcons.chevronsRight,
                      size: 18,
                      color: AppColors.gray400,
                    ),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.logOut,
                    title: 'Logout',
                    subtitle:
                        'Remove local admin credentials from this browser.',
                    trailing: const Icon(
                      LucideIcons.chevronsRight,
                      size: 18,
                      color: AppColors.gray400,
                    ),
                    onTap: _handleLogout,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsSection(
                title: 'About',
                subtitle: 'Project metadata for this administration workspace.',
                icon: LucideIcons.info,
                children: const [
                  _SettingsTile(
                    icon: LucideIcons.badgeInfo,
                    title: 'MuSheet Admin',
                    subtitle: 'Version 1.0.0',
                  ),
                  _SettingsTile(
                    icon: LucideIcons.code,
                    title: 'Built with',
                    subtitle: 'Flutter Web + Riverpod + Serverpod',
                  ),
                ],
              ),
            ],
          );

          final systemColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_healthError != null) ...[
                AdminInlineMessage(
                  icon: LucideIcons.circleAlert,
                  message: _healthError!,
                  color: AppColors.red600,
                  backgroundColor: AppColors.red50,
                ),
                const SizedBox(height: 16),
              ],
              _SettingsSection(
                title: 'System',
                subtitle: 'Runtime health and environment connectivity.',
                icon: LucideIcons.serverCog,
                children: [
                  _SettingsTile(
                    icon: LucideIcons.activity,
                    title: 'Server health',
                    subtitle: _isHealthy == null
                        ? 'Run a health check to verify backend availability.'
                        : _isHealthy!
                            ? 'Server is healthy and responding normally.'
                            : _healthError ?? 'Server health check failed.',
                    trailing: _isCheckingHealth
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isHealthy == null
                                ? LucideIcons.chevronsRight
                                : _isHealthy!
                                    ? LucideIcons.circleCheckBig
                                    : LucideIcons.circleAlert,
                            size: 18,
                            color: _isHealthy == null
                                ? AppColors.gray400
                                : _isHealthy!
                                    ? AppColors.emerald600
                                    : AppColors.red600,
                          ),
                    onTap: _isCheckingHealth ? null : _checkHealth,
                  ),
                  _SettingsTile(
                    icon: LucideIcons.link,
                    title: 'API endpoint',
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
              _SettingsSection(
                title: 'Roadmap configuration',
                subtitle:
                    'Upcoming administrative capabilities reserved for future iterations.',
                icon: LucideIcons.sparkles,
                children: const [
                  _SettingsTile(
                    icon: LucideIcons.userPlus,
                    title: 'Registration control',
                    subtitle:
                        'Enable or disable self-service account registration.',
                    enabled: false,
                    trailing: Switch(value: true, onChanged: null),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.database,
                    title: 'Storage quotas',
                    subtitle: 'Set storage policies for users and teams.',
                    enabled: false,
                    trailing: Icon(
                      LucideIcons.chevronsRight,
                      size: 18,
                      color: AppColors.gray400,
                    ),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.clipboardList,
                    title: 'Audit logs',
                    subtitle: 'Review administrative operations and events.',
                    enabled: false,
                    trailing: Icon(
                      LucideIcons.chevronsRight,
                      size: 18,
                      color: AppColors.gray400,
                    ),
                  ),
                  _SettingsTile(
                    icon: LucideIcons.download,
                    title: 'Data export',
                    subtitle: 'Export platform snapshots and operational data.',
                    enabled: false,
                    trailing: Icon(
                      LucideIcons.chevronsRight,
                      size: 18,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                accountColumn,
                const SizedBox(height: 24),
                systemColumn,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: accountColumn),
              const SizedBox(width: 24),
              Expanded(child: systemColumn),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      contentPadding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, indent: 72, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

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
    final child = Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled ? AppColors.gray100 : AppColors.gray50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 20,
              color: enabled ? AppColors.gray700 : AppColors.gray400,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: enabled ? AppColors.gray900 : AppColors.gray500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray500,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: child,
        ),
      ),
    );
  }
}
