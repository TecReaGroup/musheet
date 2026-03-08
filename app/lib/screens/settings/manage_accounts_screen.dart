import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/core.dart';
import '../../providers/auth_flow_provider.dart';
import '../../providers/core_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../utils/icon_mappings.dart';
import '../../widgets/common_widgets.dart';
import 'settings_sub_screen.dart';

class ManageAccountsScreen extends ConsumerStatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  ConsumerState<ManageAccountsScreen> createState() =>
      _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends ConsumerState<ManageAccountsScreen> {
  String? _busyAccountKey;

  void _showSuccessToast(String message) {
    if (!mounted) return;
    AppToast.success(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(currentAccountRegistryProvider);
    final activeContext = registry.activeContext;
    final savedAccounts = registry.savedAccounts;

    return SettingsSubScreen(
      title: 'Manage Accounts',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'CURRENT CONTEXT',
            child: _AccountActionTile(
              leading: const Icon(
                AppIcons.libraryMusic,
                color: AppColors.gray600,
              ),
              title: 'Local Library',
              subtitle: 'On this device',
              trailing: activeContext.isLocal
                  ? const Icon(
                      AppIcons.check,
                      size: 18,
                      color: AppColors.blue600,
                    )
                  : TextButton(
                      onPressed: _busyAccountKey != null
                          ? null
                          : () async {
                              setState(() => _busyAccountKey = 'local');
                              try {
                                await ref
                                    .read(authFlowCoordinatorProvider)
                                    .switchToLocal();
                                _showSuccessToast('Switched to Local Library');
                              } finally {
                                if (mounted) {
                                  setState(() => _busyAccountKey = null);
                                }
                              }
                            },
                      child: const Text('Switch'),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'SAVED ACCOUNTS',
            child: savedAccounts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No saved accounts on this device yet.',
                      style: TextStyle(color: AppColors.gray500),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < savedAccounts.length; i++)
                        _SavedAccountTile(
                          account: savedAccounts[i],
                          isActive:
                              activeContext.accountKey ==
                              savedAccounts[i].accountKey,
                          isBusy: _busyAccountKey == savedAccounts[i].accountKey,
                          showDivider: i != savedAccounts.length - 1,
                          onSwitch: () async {
                            setState(
                              () => _busyAccountKey = savedAccounts[i].accountKey,
                            );
                            try {
                              await ref
                                  .read(authFlowCoordinatorProvider)
                                  .switchToAccount(savedAccounts[i].accountKey);
                              _showSuccessToast('Switched account');
                            } finally {
                              if (mounted) {
                                setState(() => _busyAccountKey = null);
                              }
                            }
                          },
                          onReauthenticate: () {
                            context.go(
                              AppRoutes.loginWithMode(
                                'reauthenticate',
                                accountKey: savedAccounts[i].accountKey,
                              ),
                            );
                          },
                          onRemove: () async {
                            final confirmed = await _confirmRemoveAccount(
                              context,
                              savedAccounts[i],
                            );
                            if (confirmed != true || !mounted) return;

                            setState(
                              () => _busyAccountKey = savedAccounts[i].accountKey,
                            );
                            try {
                              await ref
                                  .read(authFlowCoordinatorProvider)
                                  .removeAccount(savedAccounts[i].accountKey);
                              _showSuccessToast(
                                'Account removed from this device',
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _busyAccountKey = null);
                              }
                            }
                          },
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.loginWithMode('addAccount')),
              icon: const Icon(AppIcons.add),
              label: const Text('Add Account'),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmRemoveAccount(
    BuildContext context,
    SavedAccount account,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Account?'),
          content: Text(
            'This will remove ${account.effectiveDisplayName} from this device and delete its local cache. Your server data will not be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.red500),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.gray500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
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
          trailing,
        ],
      ),
    );
  }
}

class _SavedAccountTile extends StatelessWidget {
  const _SavedAccountTile({
    required this.account,
    required this.isActive,
    required this.isBusy,
    required this.showDivider,
    required this.onSwitch,
    required this.onReauthenticate,
    required this.onRemove,
  });

  final SavedAccount account;
  final bool isActive;
  final bool isBusy;
  final bool showDivider;
  final VoidCallback onSwitch;
  final VoidCallback onReauthenticate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.gray100))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.blue50 : AppColors.gray100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    AppIcons.person,
                    size: 18,
                    color: isActive ? AppColors.blue600 : AppColors.gray600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              account.effectiveDisplayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray700,
                              ),
                            ),
                          ),
                          if (isActive)
                            const Icon(
                              AppIcons.check,
                              size: 18,
                              color: AppColors.blue600,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.username,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.reauthRequired
                            ? 'Sign in again required'
                            : account.serverUrl,
                        style: TextStyle(
                          fontSize: 12,
                          color: account.reauthRequired
                              ? AppColors.red500
                              : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isActive)
                  TextButton(
                    onPressed: isBusy ? null : onSwitch,
                    child: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Switch'),
                  ),
                if (account.reauthRequired)
                  TextButton(
                    onPressed: isBusy ? null : onReauthenticate,
                    child: const Text('Sign In Again'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: isBusy ? null : onRemove,
                  style: TextButton.styleFrom(foregroundColor: AppColors.red500),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
