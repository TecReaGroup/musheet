import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/admin_widgets.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _searchController = TextEditingController();
  _UserFilter _filter = _UserFilter.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authState = ref.read(adminAuthProvider);
      if (authState.isAuthenticated) {
        ref.read(usersProvider.notifier).loadUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _showCreateUserDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _CreateUserDialog(),
    );

    if (result == true && mounted) {
      AdminToast.success(context, 'User created successfully');
    }
  }

  Future<void> _handleDeactivate(int userId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Deactivate user',
      message: 'This account will lose access until it is reactivated.',
      confirmLabel: 'Deactivate',
      isDanger: true,
    );

    if (!confirmed || !mounted) return;
    final success = await ref.read(usersProvider.notifier).deactivateUser(userId);
    if (!mounted) return;
    success
        ? AdminToast.success(context, 'User deactivated')
        : AdminToast.error(context, 'Failed to deactivate user');
  }

  Future<void> _handleReactivate(int userId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Reactivate user',
      message: 'This account will regain access to the platform.',
      confirmLabel: 'Reactivate',
    );

    if (!confirmed || !mounted) return;
    final success = await ref.read(usersProvider.notifier).reactivateUser(userId);
    if (!mounted) return;
    success
        ? AdminToast.success(context, 'User activated')
        : AdminToast.error(context, 'Failed to activate user');
  }

  Future<void> _handleDelete(int userId, String username) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete user',
      message:
          'Permanently delete "$username"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (!confirmed || !mounted) return;
    final success = await ref.read(usersProvider.notifier).deleteUser(userId);
    if (!mounted) return;
    success
        ? AdminToast.success(context, 'User deleted')
        : AdminToast.error(context, 'Failed to delete user');
  }

  Future<void> _handlePromote(int userId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Promote to admin',
      message: 'Grant administrator permissions to this account?',
      confirmLabel: 'Promote',
    );

    if (!confirmed || !mounted) return;
    final success = await ref.read(usersProvider.notifier).promoteToAdmin(userId);
    if (!mounted) return;
    success
        ? AdminToast.success(context, 'User promoted to admin')
        : AdminToast.error(context, 'Failed to promote user');
  }

  Future<void> _handleDemote(int userId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Demote admin',
      message: 'Remove administrator permissions from this account?',
      confirmLabel: 'Demote',
      isDanger: true,
    );

    if (!confirmed || !mounted) return;
    final success = await ref.read(usersProvider.notifier).demoteFromAdmin(userId);
    if (!mounted) return;
    success
        ? AdminToast.success(context, 'User demoted')
        : AdminToast.error(context, 'Failed to demote user');
  }

  Future<void> _handleResetPassword(int userId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Reset password',
      message: 'Generate a temporary password for this account?',
      confirmLabel: 'Reset',
    );

    if (!confirmed || !mounted) return;

    final tempPassword = await ref.read(usersProvider.notifier).resetPassword(userId);
    if (!mounted) return;

    if (tempPassword == null) {
      AdminToast.error(context, 'Failed to reset password');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Temporary password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this password securely with the user.'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.gray200),
              ),
              child: SelectableText(
                tempPassword,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(usersProvider);
    final authState = ref.watch(adminAuthProvider);
    final searchTerm = _searchController.text.trim().toLowerCase();

    if (authState.isAuthenticated &&
        usersState.users.isEmpty &&
        !usersState.isLoading &&
        usersState.error == null) {
      Future.microtask(() => ref.read(usersProvider.notifier).loadUsers());
    }

    final filteredUsers = usersState.users.where((user) {
      final matchesFilter = switch (_filter) {
        _UserFilter.all => true,
        _UserFilter.admins => user.isAdmin,
        _UserFilter.disabled => user.isDisabled,
        _UserFilter.active => !user.isDisabled,
      };

      if (!matchesFilter) {
        return false;
      }

      if (searchTerm.isEmpty) {
        return true;
      }

      final displayName = user.displayName?.toLowerCase() ?? '';
      final username = user.username.toLowerCase();
      final id = '${user.id}';

      return username.contains(searchTerm) ||
          displayName.contains(searchTerm) ||
          id.contains(searchTerm);
    }).toList();

    if (usersState.isLoading && usersState.users.isEmpty) {
      return const Center(
        child: AdminLoadingIndicator(message: 'Loading users...'),
      );
    }

    if (usersState.error != null && usersState.users.isEmpty) {
      return Center(
        child: AdminEmptyState(
          icon: LucideIcons.circleAlert,
          title: 'Failed to load users',
          subtitle: usersState.error,
          action: ElevatedButton.icon(
            onPressed: () => ref.read(usersProvider.notifier).loadUsers(),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text('Retry'),
          ),
        ),
      );
    }

    return AdminPageScaffold(
      eyebrow: 'Accounts',
      title: 'User management',
      subtitle:
          'Manage account status, permissions, and onboarding from a cleaner workspace aligned with the app design system.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => ref.read(usersProvider.notifier).loadUsers(),
          icon: usersState.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.refreshCw, size: 18),
          label: const Text('Refresh'),
        ),
        ElevatedButton.icon(
          onPressed: _showCreateUserDialog,
          icon: const Icon(LucideIcons.userPlus, size: 18),
          label: const Text('Create user'),
        ),
      ],
      hero: AdminInfoHero(
        icon: LucideIcons.users,
        title: 'Account operations',
        subtitle:
            'Review account status, locate the right user quickly, and keep sensitive actions clearly separated from routine administration.',
        trailing: [
          AdminMetricPill(
            icon: LucideIcons.users,
            label: 'Visible users',
            value: '${usersState.users.length}',
          ),
          AdminMetricPill(
            icon: LucideIcons.shieldCheck,
            label: 'Admins',
            value: '${usersState.users.where((user) => user.isAdmin).length}',
            accent: AppColors.blue600,
          ),
          AdminMetricPill(
            icon: LucideIcons.ban,
            label: 'Disabled',
            value: '${usersState.users.where((user) => user.isDisabled).length}',
            accent: AppColors.red600,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminToolbar(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 980;

                final filters = Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AdminFilterChip(
                      label: 'All',
                      icon: LucideIcons.layoutList,
                      selected: _filter == _UserFilter.all,
                      onTap: () => setState(() => _filter = _UserFilter.all),
                    ),
                    AdminFilterChip(
                      label: 'Admins',
                      icon: LucideIcons.shieldCheck,
                      selected: _filter == _UserFilter.admins,
                      onTap: () => setState(() => _filter = _UserFilter.admins),
                    ),
                    AdminFilterChip(
                      label: 'Active',
                      icon: LucideIcons.badgeCheck,
                      selected: _filter == _UserFilter.active,
                      onTap: () => setState(() => _filter = _UserFilter.active),
                    ),
                    AdminFilterChip(
                      label: 'Disabled',
                      icon: LucideIcons.ban,
                      selected: _filter == _UserFilter.disabled,
                      onTap: () => setState(() => _filter = _UserFilter.disabled),
                    ),
                  ],
                );

                final search = SizedBox(
                  width: stacked ? double.infinity : 320,
                  child: AdminSearchField(
                    controller: _searchController,
                    hintText: 'Search username, display name, or ID',
                    onChanged: (_) => setState(() {}),
                  ),
                );

                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      filters,
                      const SizedBox(height: 14),
                      search,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: filters),
                    const SizedBox(width: 16),
                    search,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (usersState.error != null) ...[
            AdminInlineMessage(
              icon: LucideIcons.circleAlert,
              message: usersState.error!,
              color: AppColors.red600,
              backgroundColor: AppColors.red50,
            ),
            const SizedBox(height: 16),
          ],
          if (usersState.users.isEmpty)
            AdminEmptyState(
              icon: LucideIcons.users,
              title: 'No users found',
              subtitle: 'Create the first managed account to populate this table.',
              action: ElevatedButton.icon(
                onPressed: _showCreateUserDialog,
                icon: const Icon(LucideIcons.userPlus, size: 18),
                label: const Text('Create user'),
              ),
            )
          else if (filteredUsers.isEmpty)
            const AdminEmptyState(
              icon: LucideIcons.search,
              title: 'No matching users',
              subtitle: 'Adjust the current filters or search terms to see more accounts.',
            )
          else ...[
            DataTableCard(
              title: 'Directory',
              subtitle:
                  'Role, lifecycle state, and recovery actions for the current filtered result set.',
              icon: LucideIcons.table2,
              child: AdminResponsiveDataTable(
                minWidth: 1120,
                columns: const [
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Display Name')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Created')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: filteredUsers.map((user) {
                  final isCurrentUser = user.id == authState.userId;

                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 240,
                          child: Row(
                            children: [
                              AdminUserAvatar(
                                name: user.displayName ?? user.username,
                                userId: user.id,
                                size: 36,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.username,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.gray900,
                                      ),
                                    ),
                                    Text(
                                      'ID ${user.id}',
                                      style: const TextStyle(
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
                      ),
                      DataCell(Text(user.displayName ?? '-')),
                      DataCell(
                        user.isAdmin ? StatusBadge.admin() : StatusBadge.user(),
                      ),
                      DataCell(
                        user.isDisabled
                            ? StatusBadge.disabled()
                            : StatusBadge.active(),
                      ),
                      DataCell(Text(_formatDate(user.createdAt))),
                      DataCell(
                        isCurrentUser
                            ? const Text(
                                'Current session',
                                style: TextStyle(
                                  color: AppColors.gray500,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (user.isDisabled)
                                    ActionIconButton(
                                      icon: LucideIcons.badgeCheck,
                                      tooltip: 'Reactivate',
                                      color: AppColors.emerald600,
                                      onPressed: () => _handleReactivate(user.id),
                                    )
                                  else
                                    ActionIconButton(
                                      icon: LucideIcons.ban,
                                      tooltip: 'Deactivate',
                                      color: AppColors.red600,
                                      onPressed: () => _handleDeactivate(user.id),
                                    ),
                                  if (user.isAdmin)
                                    ActionIconButton(
                                      icon: LucideIcons.userMinus,
                                      tooltip: 'Demote',
                                      onPressed: () => _handleDemote(user.id),
                                    )
                                  else
                                    ActionIconButton(
                                      icon: LucideIcons.shieldPlus,
                                      tooltip: 'Promote',
                                      onPressed: () => _handlePromote(user.id),
                                    ),
                                  ActionIconButton(
                                    icon: LucideIcons.keyRound,
                                    tooltip: 'Reset password',
                                    onPressed: () => _handleResetPassword(user.id),
                                  ),
                                  ActionIconButton(
                                    icon: LucideIcons.trash2,
                                    tooltip: 'Delete',
                                    isDanger: true,
                                    onPressed: () => _handleDelete(
                                      user.id,
                                      user.username,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            if (searchTerm.isEmpty && _filter == _UserFilter.all)
              PaginationControls(
                currentPage: usersState.page,
                hasMore: usersState.hasMore,
                isLoading: usersState.isLoading,
                onPrevious: () => ref.read(usersProvider.notifier).previousPage(),
                onNext: () => ref.read(usersProvider.notifier).nextPage(),
              ),
          ],
        ],
      ),
    );
  }
}

enum _UserFilter { all, admins, active, disabled }

class _CreateUserDialog extends ConsumerStatefulWidget {
  const _CreateUserDialog();

  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isAdmin = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await ref.read(usersProvider.notifier).createUser(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim().isEmpty
              ? null
              : _displayNameController.text.trim(),
          isAdmin: _isAdmin,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isLoading = false;
      _error = 'Failed to create user';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create user'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username *',
                  hintText: 'Enter username',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Initial password *',
                  hintText: 'Minimum 6 characters',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  hintText: 'Optional name shown in UI',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: CheckboxListTile(
                  value: _isAdmin,
                  onChanged: (value) => setState(() => _isAdmin = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Grant admin privileges'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                AdminInlineMessage(
                  icon: LucideIcons.circleAlert,
                  message: _error!,
                  color: AppColors.red600,
                  backgroundColor: AppColors.red50,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleCreate,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(LucideIcons.userPlus, size: 18),
          label: const Text('Create user'),
        ),
      ],
    );
  }
}
