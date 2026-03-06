import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/admin_widgets.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  @override
  void initState() {
    super.initState();
    // Load users on init
    Future.microtask(() {
      ref.read(usersProvider.notifier).loadUsers();
    });
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
      title: 'Deactivate User',
      message: 'Are you sure you want to deactivate this user?',
      confirmLabel: 'Deactivate',
      isDanger: true,
    );

    if (confirmed && mounted) {
      final success = await ref.read(usersProvider.notifier).deactivateUser(userId);
      if (mounted) {
        if (success) {
          AdminToast.success(context, 'User deactivated');
        } else {
          AdminToast.error(context, 'Failed to deactivate user');
        }
      }
    }
  }

  Future<void> _handleReactivate(int userId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Activate User',
      message: 'Are you sure you want to activate this user?',
      confirmLabel: 'Activate',
    );

    if (confirmed && mounted) {
      final success = await ref.read(usersProvider.notifier).reactivateUser(userId);
      if (mounted) {
        if (success) {
          AdminToast.success(context, 'User activated');
        } else {
          AdminToast.error(context, 'Failed to activate user');
        }
      }
    }
  }

  Future<void> _handleDelete(int userId, String username) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete User',
      message:
          'Are you sure you want to permanently delete "$username"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (confirmed && mounted) {
      final success = await ref.read(usersProvider.notifier).deleteUser(userId);
      if (mounted) {
        if (success) {
          AdminToast.success(context, 'User deleted');
        } else {
          AdminToast.error(context, 'Failed to delete user');
        }
      }
    }
  }

  Future<void> _handlePromote(int userId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Promote to Admin',
      message: 'Are you sure you want to give this user admin privileges?',
      confirmLabel: 'Promote',
    );

    if (confirmed && mounted) {
      final success = await ref.read(usersProvider.notifier).promoteToAdmin(userId);
      if (mounted) {
        if (success) {
          AdminToast.success(context, 'User promoted to admin');
        } else {
          AdminToast.error(context, 'Failed to promote user');
        }
      }
    }
  }

  Future<void> _handleDemote(int userId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Demote from Admin',
      message: 'Are you sure you want to remove admin privileges from this user?',
      confirmLabel: 'Demote',
      isDanger: true,
    );

    if (confirmed && mounted) {
      final success = await ref.read(usersProvider.notifier).demoteFromAdmin(userId);
      if (mounted) {
        if (success) {
          AdminToast.success(context, 'User demoted');
        } else {
          AdminToast.error(context, 'Failed to demote user');
        }
      }
    }
  }

  Future<void> _handleResetPassword(int userId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Reset Password',
      message: 'This will generate a new temporary password. Continue?',
      confirmLabel: 'Reset',
    );

    if (confirmed && mounted) {
      final tempPassword = await ref.read(usersProvider.notifier).resetPassword(userId);
      if (mounted) {
        if (tempPassword != null) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Password Reset'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Temporary password:'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.slate800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      tempPassword,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please share this with the user securely.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.gray500,
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
        } else {
          AdminToast.error(context, 'Failed to reset password');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(usersProvider);
    final authState = ref.watch(adminAuthProvider);

    return Scaffold(
      backgroundColor: AppColors.slate900,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: AppColors.slate800,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Management',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage user accounts and permissions',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateUserDialog,
                  icon: const Icon(LucideIcons.userPlus, size: 18),
                  label: const Text('Create User'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.slate700),

          // Content
          Expanded(
            child: usersState.isLoading && usersState.users.isEmpty
                ? const AdminLoadingIndicator(message: 'Loading users...')
                : usersState.error != null
                    ? AdminEmptyState(
                        icon: LucideIcons.circleAlert,
                        title: 'Failed to load users',
                        subtitle: usersState.error,
                        action: ElevatedButton.icon(
                          onPressed: () =>
                              ref.read(usersProvider.notifier).loadUsers(),
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          label: const Text('Retry'),
                        ),
                      )
                    : usersState.users.isEmpty
                        ? AdminEmptyState(
                            icon: LucideIcons.users,
                            title: 'No users found',
                            action: ElevatedButton.icon(
                              onPressed: _showCreateUserDialog,
                              icon: const Icon(LucideIcons.userPlus, size: 16),
                              label: const Text('Create User'),
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: DataTableCard(
                                    title: 'Users',
                                    icon: LucideIcons.users,
                                    actions: [
                                      if (usersState.isLoading)
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                    ],
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        columns: const [
                                          DataColumn(label: Text('ID')),
                                          DataColumn(label: Text('Username')),
                                          DataColumn(label: Text('Display Name')),
                                          DataColumn(label: Text('Role')),
                                          DataColumn(label: Text('Status')),
                                          DataColumn(label: Text('Created')),
                                          DataColumn(label: Text('Actions')),
                                        ],
                                        rows: usersState.users.map((user) {
                                          final isCurrentUser =
                                              user.id == authState.userId;

                                          return DataRow(
                                            cells: [
                                              DataCell(Text('${user.id}')),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    AdminUserAvatar(
                                                      name: user.displayName ??
                                                          user.username,
                                                      size: 32,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      user.username,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                Text(user.displayName ?? '-'),
                                              ),
                                              DataCell(
                                                user.isAdmin
                                                    ? StatusBadge.admin()
                                                    : StatusBadge.user(),
                                              ),
                                              DataCell(
                                                user.isDisabled
                                                    ? StatusBadge.disabled()
                                                    : StatusBadge.active(),
                                              ),
                                              DataCell(
                                                Text(_formatDate(user.createdAt)),
                                              ),
                                              DataCell(
                                                isCurrentUser
                                                    ? const Text(
                                                        'Current User',
                                                        style: TextStyle(
                                                          color: AppColors.gray400,
                                                          fontSize: 12,
                                                        ),
                                                      )
                                                    : Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          if (user.isDisabled)
                                                            ActionIconButton(
                                                              icon: LucideIcons.check,
                                                              tooltip: 'Activate',
                                                              color:
                                                                  AppColors.emerald600,
                                                              onPressed: () =>
                                                                  _handleReactivate(
                                                                      user.id),
                                                            )
                                                          else
                                                            ActionIconButton(
                                                              icon: LucideIcons.ban,
                                                              tooltip: 'Deactivate',
                                                              onPressed: () =>
                                                                  _handleDeactivate(
                                                                      user.id),
                                                            ),
                                                          if (user.isAdmin)
                                                            ActionIconButton(
                                                              icon:
                                                                  LucideIcons.userMinus,
                                                              tooltip: 'Demote',
                                                              onPressed: () =>
                                                                  _handleDemote(
                                                                      user.id),
                                                            )
                                                          else
                                                            ActionIconButton(
                                                              icon: LucideIcons.shield,
                                                              tooltip: 'Promote',
                                                              onPressed: () =>
                                                                  _handlePromote(
                                                                      user.id),
                                                            ),
                                                          ActionIconButton(
                                                            icon: LucideIcons.key,
                                                            tooltip: 'Reset Password',
                                                            onPressed: () =>
                                                                _handleResetPassword(
                                                                    user.id),
                                                          ),
                                                          ActionIconButton(
                                                            icon: LucideIcons.trash2,
                                                            tooltip: 'Delete',
                                                            isDanger: true,
                                                            onPressed: () =>
                                                                _handleDelete(
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
                                  ),
                                ),
                              ),
                              PaginationControls(
                                currentPage: usersState.page,
                                hasMore: usersState.hasMore,
                                isLoading: usersState.isLoading,
                                onPrevious: () =>
                                    ref.read(usersProvider.notifier).previousPage(),
                                onNext: () =>
                                    ref.read(usersProvider.notifier).nextPage(),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Create User Dialog
// ============================================================================

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

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to create user';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(LucideIcons.userPlus, size: 20),
          SizedBox(width: 10),
          Text('Create User'),
        ],
      ),
      content: SizedBox(
        width: 400,
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
                  labelText: 'Initial Password *',
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
                  labelText: 'Display Name (optional)',
                  hintText: 'Enter display name',
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _isAdmin,
                onChanged: (value) => setState(() => _isAdmin = value ?? false),
                title: const Text('Admin privileges'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.red400,
                      fontSize: 13,
                    ),
                  ),
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
              : const Icon(LucideIcons.userPlus, size: 16),
          label: const Text('Create'),
        ),
      ],
    );
  }
}
