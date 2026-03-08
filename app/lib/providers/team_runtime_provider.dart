library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'teams_state_provider.dart';

class TeamRuntimeCoordinator {
  TeamRuntimeCoordinator(this.ref);

  final Ref ref;

  Future<void> setTeamEnabled(bool enabled) async {
    if (!enabled) {
      await ref.read(teamsStateProvider.notifier).leaveAllTeams();
    } else {
      await ref.read(teamsStateProvider.notifier).refresh();
    }
  }
}

final teamRuntimeCoordinatorProvider = Provider<TeamRuntimeCoordinator>((ref) {
  return TeamRuntimeCoordinator(ref);
});
