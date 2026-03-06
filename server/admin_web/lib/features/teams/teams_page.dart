import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:musheet_client/musheet_client.dart' as server;
import '../../core/admin_api_client.dart';
import '../../core/providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/admin_widgets.dart';

class TeamsPage extends ConsumerStatefulWidget {
  const TeamsPage({super.key});

  @override
  ConsumerState<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends ConsumerState<TeamsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(teamsProvider.notifier).loadTeams();
    });
  }

  Future<void> _showCreateTeamDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _CreateTeamDialog(),
    );

    if (result == true && mounted) {
      AdminToast.success(context, 'Team created successfully');
    }
  }

  Future<void> _handleDeleteTeam(int teamId, String teamName) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Team',
      message:
          'Are you sure you want to permanently delete "$teamName"? All shared scores and members will be removed.',
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (confirmed && mounted) {
      final success = await ref.read(teamsProvider.notifier).deleteTeam(teamId);
      if (mounted) {
        if (success) {
          AdminToast.success(context, 'Team deleted');
        } else {
          AdminToast.error(context, 'Failed to delete team');
        }
      }
    }
  }

  Future<void> _showTeamMembersDialog(int teamId, String teamName) async {
    await showDialog(
      context: context,
      builder: (context) => _TeamMembersDialog(teamId: teamId, teamName: teamName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamsState = ref.watch(teamsProvider);

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
                        'Team Management',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create and manage teams',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateTeamDialog,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Create Team'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.slate700),

          // Content
          Expanded(
            child: teamsState.isLoading && teamsState.teams.isEmpty
                ? const AdminLoadingIndicator(message: 'Loading teams...')
                : teamsState.error != null
                    ? AdminEmptyState(
                        icon: LucideIcons.circleAlert,
                        title: 'Failed to load teams',
                        subtitle: teamsState.error,
                        action: ElevatedButton.icon(
                          onPressed: () =>
                              ref.read(teamsProvider.notifier).loadTeams(),
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          label: const Text('Retry'),
                        ),
                      )
                    : teamsState.teams.isEmpty
                        ? AdminEmptyState(
                            icon: LucideIcons.users,
                            title: 'No teams found',
                            subtitle: 'Create a team to get started',
                            action: ElevatedButton.icon(
                              onPressed: _showCreateTeamDialog,
                              icon: const Icon(LucideIcons.plus, size: 16),
                              label: const Text('Create Team'),
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: DataTableCard(
                                    title: 'Teams',
                                    icon: LucideIcons.users,
                                    actions: [
                                      if (teamsState.isLoading)
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
                                          DataColumn(label: Text('Team Name')),
                                          DataColumn(
                                              label: Text('Members'), numeric: true),
                                          DataColumn(
                                              label: Text('Shared Scores'),
                                              numeric: true),
                                          DataColumn(label: Text('Actions')),
                                        ],
                                        rows: teamsState.teams.map((team) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text('${team.id}')),
                                              DataCell(
                                                Text(
                                                  team.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                StatusBadge.count(
                                                  count: team.memberCount,
                                                  icon: LucideIcons.users,
                                                  color: AppColors.indigo500,
                                                ),
                                              ),
                                              DataCell(
                                                StatusBadge.count(
                                                  count: team.sharedScores,
                                                  icon: LucideIcons.music,
                                                  color: AppColors.emerald500,
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    ActionIconButton(
                                                      icon: LucideIcons.users,
                                                      tooltip: 'View Members',
                                                      onPressed: () =>
                                                          _showTeamMembersDialog(
                                                        team.id,
                                                        team.name,
                                                      ),
                                                    ),
                                                    ActionIconButton(
                                                      icon: LucideIcons.trash2,
                                                      tooltip: 'Delete',
                                                      isDanger: true,
                                                      onPressed: () =>
                                                          _handleDeleteTeam(
                                                        team.id,
                                                        team.name,
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
                                currentPage: teamsState.page,
                                hasMore: teamsState.hasMore,
                                isLoading: teamsState.isLoading,
                                onPrevious: () =>
                                    ref.read(teamsProvider.notifier).previousPage(),
                                onNext: () =>
                                    ref.read(teamsProvider.notifier).nextPage(),
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
// Create Team Dialog
// ============================================================================

class _CreateTeamDialog extends ConsumerStatefulWidget {
  const _CreateTeamDialog();

  @override
  ConsumerState<_CreateTeamDialog> createState() => _CreateTeamDialogState();
}

class _CreateTeamDialogState extends ConsumerState<_CreateTeamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await ref.read(teamsProvider.notifier).createTeam(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to create team';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(LucideIcons.plus, size: 20),
          SizedBox(width: 10),
          Text('Create Team'),
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
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name *',
                  hintText: 'Enter team name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Team name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Enter description',
                ),
                maxLines: 3,
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
              : const Icon(LucideIcons.plus, size: 16),
          label: const Text('Create'),
        ),
      ],
    );
  }
}

// ============================================================================
// Team Members Dialog
// ============================================================================

class _TeamMembersDialog extends ConsumerStatefulWidget {
  final int teamId;
  final String teamName;

  const _TeamMembersDialog({required this.teamId, required this.teamName});

  @override
  ConsumerState<_TeamMembersDialog> createState() => _TeamMembersDialogState();
}

class _TeamMembersDialogState extends ConsumerState<_TeamMembersDialog> {
  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _showAddMemberDialog() async {
    // First load all users
    final usersResult = await AdminApiClient.instance.getAllUsers(page: 0, pageSize: 1000);
    if (usersResult.isFailure || usersResult.data == null) {
      if (mounted) {
        AdminToast.error(context, 'Failed to load users');
      }
      return;
    }

    if (!mounted) return;

    final selectedUserId = await showDialog<int>(
      context: context,
      builder: (context) => _AddMemberDialog(users: usersResult.data!),
    );

    if (selectedUserId != null && mounted) {
      final result =
          await AdminApiClient.instance.addMemberToTeam(widget.teamId, selectedUserId);
      if (mounted) {
        if (result.isSuccess) {
          AdminToast.success(context, 'Member added');
          ref.invalidate(teamMembersProvider(widget.teamId));
          ref.read(teamsProvider.notifier).loadTeams();
        } else {
          AdminToast.error(context, result.error ?? 'Failed to add member');
        }
      }
    }
  }

  Future<void> _handleRemoveMember(int userId, String username) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Remove Member',
      message: 'Remove "$username" from this team?',
      confirmLabel: 'Remove',
      isDanger: true,
    );

    if (confirmed && mounted) {
      final result =
          await AdminApiClient.instance.removeMemberFromTeam(widget.teamId, userId);
      if (mounted) {
        if (result.isSuccess) {
          AdminToast.success(context, 'Member removed');
          ref.invalidate(teamMembersProvider(widget.teamId));
          ref.read(teamsProvider.notifier).loadTeams();
        } else {
          AdminToast.error(context, 'Failed to remove member');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider(widget.teamId));

    return AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.users, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('${widget.teamName} - Members')),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddMemberDialog,
                  icon: const Icon(LucideIcons.userPlus, size: 16),
                  label: const Text('Add Member'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: membersAsync.when(
                loading: () =>
                    const AdminLoadingIndicator(message: 'Loading members...'),
                error: (error, _) => AdminEmptyState(
                  icon: LucideIcons.circleAlert,
                  title: 'Failed to load members',
                  subtitle: error.toString(),
                ),
                data: (members) {
                  if (members.isEmpty) {
                    return const AdminEmptyState(
                      icon: LucideIcons.users,
                      title: 'No members in this team',
                    );
                  }

                  return SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Username')),
                        DataColumn(label: Text('Display Name')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Joined')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: members.map((member) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AdminUserAvatar(
                                    name: member.displayName ?? member.username,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    member.username,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(member.displayName ?? '-')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.slate700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Member',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray300,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(_formatDate(member.joinedAt))),
                            DataCell(
                              ActionIconButton(
                                icon: LucideIcons.userMinus,
                                tooltip: 'Remove',
                                isDanger: true,
                                onPressed: () => _handleRemoveMember(
                                  member.userId,
                                  member.username,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// ============================================================================
// Add Member Dialog
// ============================================================================

class _AddMemberDialog extends StatefulWidget {
  final List<server.UserInfo> users;

  const _AddMemberDialog({required this.users});

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  int? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(LucideIcons.userPlus, size: 20),
          SizedBox(width: 10),
          Text('Add Team Member'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedUserId,
              decoration: const InputDecoration(
                labelText: 'Select User *',
              ),
              items: widget.users.map((user) {
                return DropdownMenuItem(
                  value: user.id,
                  child: Text(
                    '${user.username} (${user.displayName ?? "No name"})',
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedUserId = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _selectedUserId != null
              ? () => Navigator.of(context).pop(_selectedUserId)
              : null,
          icon: const Icon(LucideIcons.userPlus, size: 16),
          label: const Text('Add'),
        ),
      ],
    );
  }
}
