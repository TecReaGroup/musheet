import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/teams_provider.dart';
import '../theme/app_colors.dart';
import '../models/team.dart';
import '../utils/icon_mappings.dart';

enum TeamTab { setlists, scores, members }

class TeamTabNotifier extends Notifier<TeamTab> {
  @override
  TeamTab build() => TeamTab.setlists;
  
  @override
  set state(TeamTab newState) => super.state = newState;
}

class ShowTeamSwitcherNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  @override
  set state(bool newState) => super.state = newState;
}

class ShowInviteModalNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  @override
  set state(bool newState) => super.state = newState;
}

final teamTabProvider = NotifierProvider<TeamTabNotifier, TeamTab>(TeamTabNotifier.new);
final showTeamSwitcherProvider = NotifierProvider<ShowTeamSwitcherNotifier, bool>(ShowTeamSwitcherNotifier.new);
final showInviteModalProvider = NotifierProvider<ShowInviteModalNotifier, bool>(ShowInviteModalNotifier.new);

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleInvite() {
    if (_emailController.text.trim().isEmpty) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invitation sent to ${_emailController.text}')),
    );
    
    _emailController.clear();
    ref.read(showInviteModalProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(teamsProvider);
    final currentTeam = ref.watch(currentTeamProvider);
    final activeTab = ref.watch(teamTabProvider);
    final showTeamSwitcher = ref.watch(showTeamSwitcherProvider);
    final showInviteModal = ref.watch(showInviteModalProvider);

    if (currentTeam == null) {
      return const Scaffold(
        body: Center(child: Text('No team selected')),
      );
    }

    // Safely get current user role
    String currentUserRole = 'member';
    if (currentTeam.members.isNotEmpty) {
      final currentUser = currentTeam.members.where((m) => m.name == 'You').firstOrNull;
      currentUserRole = currentUser?.role ?? currentTeam.members.first.role;
    }
    final isAdmin = currentUserRole == 'admin';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.gray200)),
                ),
                // Add top safe area padding
                padding: EdgeInsets.fromLTRB(16, 24 + MediaQuery.of(context).padding.top, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentTeam.name,
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.gray700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => ref.read(showTeamSwitcherProvider.notifier).state = !showTeamSwitcher,
                          icon: const Icon(AppIcons.keyboardArrowDown, size: 28, color: AppColors.gray600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentTeam.sharedSetlists.length} setlists · ${currentTeam.sharedScores.length} scores · ${currentTeam.members.length} members',
                      style: const TextStyle(fontSize: 14, color: AppColors.gray600),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TeamTabButton(
                            label: 'Setlists',
                            icon: AppIcons.setlistIcon,
                            isActive: activeTab == TeamTab.setlists,
                            activeColor: AppColors.emerald600,
                            onTap: () => ref.read(teamTabProvider.notifier).state = TeamTab.setlists,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TeamTabButton(
                            label: 'Scores',
                            icon: AppIcons.musicNote,
                            isActive: activeTab == TeamTab.scores,
                            activeColor: AppColors.blue600,
                            onTap: () => ref.read(teamTabProvider.notifier).state = TeamTab.scores,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TeamTabButton(
                            label: 'Members',
                            icon: AppIcons.people,
                            isActive: activeTab == TeamTab.members,
                            activeColor: AppColors.indigo600,
                            onTap: () => ref.read(teamTabProvider.notifier).state = TeamTab.members,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
                  children: [
                    if (activeTab == TeamTab.setlists) _buildSetlistsTab(currentTeam),
                    if (activeTab == TeamTab.scores) _buildScoresTab(currentTeam),
                    if (activeTab == TeamTab.members) _buildMembersTab(currentTeam, isAdmin),
                  ],
                ),
              ),
            ],
          ),
          if (showTeamSwitcher) _buildTeamSwitcher(teams, currentTeam),
          if (showInviteModal) _buildInviteModal(),
        ],
      ),
    );
  }

  Widget _buildSetlistsTab(TeamData team) {
    if (team.sharedSetlists.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: Column(
            children: [
              Icon(AppIcons.setlistIcon, size: 64, color: AppColors.gray300),
              SizedBox(height: 16),
              Text('No shared setlists', style: TextStyle(fontSize: 18, color: AppColors.gray600)),
              SizedBox(height: 8),
              Text('Admins can share setlists with the team', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: team.sharedSetlists.map((setlist) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(12)),
                child: const Icon(AppIcons.setlistIcon, size: 24, color: AppColors.emerald600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(setlist.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(setlist.description, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
                    Row(
                      children: [
                        const Icon(AppIcons.people, size: 14, color: AppColors.gray400),
                        const SizedBox(width: 4),
                        Text(
                          '${setlist.scores.length} scores • Shared with ${team.members.length} members',
                          style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScoresTab(TeamData team) {
    if (team.sharedScores.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: Column(
            children: [
              Icon(AppIcons.musicNote, size: 64, color: AppColors.gray300),
              SizedBox(height: 16),
              Text('No shared scores', style: TextStyle(fontSize: 18, color: AppColors.gray600)),
              SizedBox(height: 8),
              Text('Admins can share scores with the team', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: team.sharedScores.map((score) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(12)),
                child: const Icon(AppIcons.musicNote, size: 24, color: AppColors.blue600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(score.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(score.composer, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
                    Row(
                      children: [
                        const Icon(AppIcons.people, size: 14, color: AppColors.gray400),
                        const SizedBox(width: 4),
                        Text(
                          'Shared with ${team.members.length} members',
                          style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMembersTab(TeamData team, bool isAdmin) {
    return Column(
      children: [
        ...team.members.map((member) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.blue500, Color(0xFF9333EA)]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      member.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (member.role == 'admin') ...[
                            const SizedBox(width: 8),
                            const Icon(AppIcons.workspacePremium, size: 16, color: Color(0xFFEAB308)),
                          ],
                        ],
                      ),
                      Text(member.email, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        if (isAdmin)
          Material(
            color: AppColors.blue50,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => ref.read(showInviteModalProvider.notifier).state = true,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.add, color: AppColors.blue600),
                    SizedBox(width: 8),
                    Text('Invite Member', style: TextStyle(color: AppColors.blue600, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTeamSwitcher(List<TeamData> teams, TeamData currentTeam) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => ref.read(showTeamSwitcherProvider.notifier).state = false,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          top: 80,
          left: 16,
          child: Container(
            width: 256,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: teams.map((team) {
                final isCurrentTeam = team.id == currentTeam.id;
                return Material(
                  color: isCurrentTeam ? AppColors.blue50 : Colors.white,
                  child: InkWell(
                    onTap: () {
                      ref.read(currentTeamIdProvider.notifier).state = team.id;
                      ref.read(showTeamSwitcherProvider.notifier).state = false;
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(AppIcons.people, size: 18, color: isCurrentTeam ? AppColors.blue600 : AppColors.gray400),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  team.name,
                                  style: TextStyle(fontSize: 14, color: isCurrentTeam ? AppColors.blue600 : AppColors.gray900),
                                ),
                                Text(
                                  '${team.members.length} ${team.members.length == 1 ? "member" : "members"}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrentTeam) const Icon(AppIcons.check, size: 16, color: AppColors.blue600),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInviteModal() {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              ref.read(showInviteModalProvider.notifier).state = false;
              _emailController.clear();
            },
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Invite Member', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    IconButton(
                      onPressed: () {
                        ref.read(showInviteModalProvider.notifier).state = false;
                        _emailController.clear();
                      },
                      icon: const Icon(AppIcons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: const Icon(AppIcons.email, color: AppColors.gray400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(showInviteModalProvider.notifier).state = false;
                          _emailController.clear();
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleInvite,
                        child: const Text('Send Invite'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _TeamTabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? activeColor : AppColors.gray100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isActive ? Colors.white : AppColors.gray600),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isActive ? Colors.white : AppColors.gray600, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}