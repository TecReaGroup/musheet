import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    Future.microtask(() => ref.read(teamsProvider.notifier).loadTeams());
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
      title: 'Delete team',
      message:
          'Permanently delete "$teamName" and remove its shared resources?',
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (!confirmed || !mounted) return;

    final success = await ref.read(teamsProvider.notifier).deleteTeam(teamId);
    if (!mounted) return;

    success
        ? AdminToast.success(context, 'Team deleted')
        : AdminToast.error(context, 'Failed to delete team');
  }

  Future<void> _showTeamMembersDialog(int teamId, String teamName) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _TeamMembersDialog(teamId: teamId, teamName: teamName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamsState = ref.watch(teamsProvider);

    if (teamsState.isLoading && teamsState.teams.isEmpty) {
      return const Center(
        child: AdminLoadingIndicator(message: 'Loading teams...'),
      );
    }

    if (teamsState.error != null && teamsState.teams.isEmpty) {
      return Center(
        child: AdminEmptyState(
          icon: LucideIcons.circleAlert,
          title: 'Failed to load teams',
          subtitle: teamsState.error,
          action: ElevatedButton.icon(
            onPressed: () => ref.read(teamsProvider.notifier).loadTeams(),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text('Retry'),
          ),
        ),
      );
    }

    return AdminPageScaffold(
      eyebrow: 'Collaboration',
      title: 'Team management',
      subtitle:
          'Create, organize, and maintain team workspaces with a cleaner admin flow aligned to the main MuSheet app.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => ref.read(teamsProvider.notifier).loadTeams(),
          icon: teamsState.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.refreshCw, size: 18),
          label: const Text('Refresh'),
        ),
        ElevatedButton.icon(
          onPressed: _showCreateTeamDialog,
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text('Create team'),
        ),
      ],
      hero: AdminInfoHero(
        icon: LucideIcons.usersRound,
        title: 'Shared workspaces',
        subtitle:
            'Track team scale, member distribution, and shared score volume from a workspace that now uses the same bright product rhythm as the app.',
        trailing: [
          AdminMetricPill(
            icon: LucideIcons.usersRound,
            label: 'Visible teams',
            value: '${teamsState.teams.length}',
            accent: AppColors.purple600,
          ),
          AdminMetricPill(
            icon: LucideIcons.users,
            label: 'Members',
            value:
                '${teamsState.teams.fold<int>(0, (sum, team) => sum + team.memberCount)}',
            accent: AppColors.blue600,
          ),
          AdminMetricPill(
            icon: LucideIcons.music,
            label: 'Shared scores',
            value:
                '${teamsState.teams.fold<int>(0, (sum, team) => sum + team.sharedScores)}',
            accent: AppColors.emerald600,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (teamsState.error != null) ...[
            AdminInlineMessage(
              icon: LucideIcons.circleAlert,
              message: teamsState.error!,
              color: AppColors.red600,
              backgroundColor: AppColors.red50,
            ),
            const SizedBox(height: 16),
          ],
          if (teamsState.teams.isEmpty)
            AdminEmptyState(
              icon: LucideIcons.usersRound,
              title: 'No teams found',
              subtitle: 'Create the first collaboration space to get started.',
              action: ElevatedButton.icon(
                onPressed: _showCreateTeamDialog,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Create team'),
              ),
            )
          else ...[
            DataTableCard(
              title: 'Teams directory',
              subtitle: 'Manage structure, membership, and shared content.',
              icon: LucideIcons.layoutList,
              child: AdminResponsiveDataTable(
                minWidth: 980,
                columns: const [
                  DataColumn(label: Text('Team')),
                  DataColumn(label: Text('Members')),
                  DataColumn(label: Text('Shared Scores')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: teamsState.teams.map((team) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray900,
                              ),
                            ),
                            Text(
                              'Team ID ${team.id}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        StatusBadge.count(
                          count: team.memberCount,
                          icon: LucideIcons.users,
                          color: AppColors.blue600,
                        ),
                      ),
                      DataCell(
                        StatusBadge.count(
                          count: team.sharedScores,
                          icon: LucideIcons.music,
                          color: AppColors.emerald600,
                        ),
                      ),
                      DataCell(
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionIconButton(
                              icon: LucideIcons.users,
                              tooltip: 'View members',
                              onPressed: () =>
                                  _showTeamMembersDialog(team.id, team.name),
                            ),
                            ActionIconButton(
                              icon: LucideIcons.trash2,
                              tooltip: 'Delete team',
                              isDanger: true,
                              onPressed: () =>
                                  _handleDeleteTeam(team.id, team.name),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            PaginationControls(
              currentPage: teamsState.page,
              hasMore: teamsState.hasMore,
              isLoading: teamsState.isLoading,
              onPrevious: () => ref.read(teamsProvider.notifier).previousPage(),
              onNext: () => ref.read(teamsProvider.notifier).nextPage(),
            ),
          ],
        ],
      ),
    );
  }
}

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

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isLoading = false;
      _error = 'Failed to create team';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create team'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Team name *',
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
                  labelText: 'Description',
                  hintText: 'Optional description',
                ),
                maxLines: 3,
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
              : const Icon(LucideIcons.plus, size: 18),
          label: const Text('Create team'),
        ),
      ],
    );
  }
}

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
    final usersResult =
        await AdminApiClient.instance.getAllUsers(page: 0, pageSize: 1000);
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

    if (selectedUserId == null || !mounted) return;

    final result =
        await AdminApiClient.instance.addMemberToTeam(widget.teamId, selectedUserId);
    if (!mounted) return;

    if (result.isSuccess) {
      AdminToast.success(context, 'Member added');
      ref.invalidate(teamMembersProvider(widget.teamId));
      ref.read(teamsProvider.notifier).loadTeams();
    } else {
      AdminToast.error(context, result.error ?? 'Failed to add member');
    }
  }

  Future<void> _handleRemoveMember(int userId, String username) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Remove member',
      message: 'Remove "$username" from this team?',
      confirmLabel: 'Remove',
      isDanger: true,
    );

    if (!confirmed || !mounted) return;

    final result =
        await AdminApiClient.instance.removeMemberFromTeam(widget.teamId, userId);
    if (!mounted) return;

    if (result.isSuccess) {
      AdminToast.success(context, 'Member removed');
      ref.invalidate(teamMembersProvider(widget.teamId));
      ref.read(teamsProvider.notifier).loadTeams();
    } else {
      AdminToast.error(context, 'Failed to remove member');
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider(widget.teamId));

    return AlertDialog(
      title: Text('${widget.teamName} members'),
      content: SizedBox(
        width: 760,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Manage membership for this workspace.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.gray500,
                        ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddMemberDialog,
                  icon: const Icon(LucideIcons.userPlus, size: 18),
                  label: const Text('Add member'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: membersAsync.when(
                loading: () => const AdminLoadingIndicator(
                  message: 'Loading members...',
                ),
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
                      subtitle: 'Add a user to start collaborating.',
                    );
                  }

                  return SingleChildScrollView(
                    child: AdminResponsiveDataTable(
                      minWidth: 700,
                      columns: const [
                        DataColumn(label: Text('User')),
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
                                children: [
                                  AdminUserAvatar(
                                    name: member.displayName ?? member.username,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    member.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.gray900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(member.displayName ?? '-')),
                            DataCell(
                              StatusBadge(
                                label: 'Member',
                                backgroundColor: AppColors.blue50,
                                textColor: AppColors.blue600,
                                icon: LucideIcons.user,
                              ),
                            ),
                            DataCell(Text(_formatDate(member.joinedAt))),
                            DataCell(
                              ActionIconButton(
                                icon: LucideIcons.userMinus,
                                tooltip: 'Remove member',
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
      title: const Text('Add team member'),
      content: SizedBox(
        width: 420,
        child: DropdownButtonFormField<int>(
          value: _selectedUserId,
          decoration: const InputDecoration(
            labelText: 'Select user *',
          ),
          items: widget.users
              .map(
                (user) => DropdownMenuItem<int>(
                  value: user.id,
                  child: Text(
                    '${user.username} (${user.displayName ?? "No name"})',
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedUserId = value),
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
          icon: const Icon(LucideIcons.userPlus, size: 18),
          label: const Text('Add member'),
        ),
      ],
    );
  }
}
