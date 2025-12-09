import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team.dart';
import 'scores_provider.dart';
import 'setlists_provider.dart';

class TeamsNotifier extends Notifier<List<TeamData>> {
  @override
  List<TeamData> build() {
    // Initialize with mock data based on available scores and setlists
    // Use scoresListProvider for synchronous access
    final scores = ref.read(scoresListProvider);
    final setlists = ref.read(setlistsProvider);
    
    if (scores.isNotEmpty && setlists.isNotEmpty) {
      return [
        TeamData(
          id: '1',
          name: 'Symphony Orchestra',
          members: [
            TeamMember(id: '1', name: 'You', email: 'you@example.com', role: 'admin'),
            TeamMember(id: '2', name: 'John Smith', email: 'john@example.com', role: 'member'),
            TeamMember(id: '3', name: 'Sarah Chen', email: 'sarah@example.com', role: 'admin'),
          ],
          sharedScores: scores.isNotEmpty ? [scores[0]] : [],
          sharedSetlists: setlists.isNotEmpty ? [setlists[0]] : [],
        ),
        TeamData(
          id: '2',
          name: 'Chamber Ensemble',
          members: [
            TeamMember(id: '1', name: 'You', email: 'you@example.com', role: 'admin'),
            TeamMember(id: '4', name: 'Emma Wilson', email: 'emma@example.com', role: 'member'),
          ],
          sharedScores: scores.length >= 3 ? [scores[1], scores[2]] : [],
          sharedSetlists: [],
        ),
        TeamData(
          id: '3',
          name: 'Jazz Quartet',
          members: [
            TeamMember(id: '1', name: 'You', email: 'you@example.com', role: 'member'),
            TeamMember(id: '5', name: 'Mike Johnson', email: 'mike@example.com', role: 'admin'),
            TeamMember(id: '6', name: 'Lisa Brown', email: 'lisa@example.com', role: 'member'),
          ],
          sharedScores: scores.length >= 4 ? [scores[3]] : [],
          sharedSetlists: setlists.length >= 2 ? [setlists[1]] : [],
        ),
      ];
    }
    return [];
  }

  /// Leave all teams - clears all team data including scores and setlists
  void leaveAllTeams() {
    state = [];
  }

  /// Rejoin teams - reinitialize with mock data
  void rejoinTeams() {
    // Use scoresListProvider for synchronous access
    final scores = ref.read(scoresListProvider);
    final setlists = ref.read(setlistsProvider);
    
    if (scores.isNotEmpty && setlists.isNotEmpty) {
      state = [
        TeamData(
          id: '1',
          name: 'Symphony Orchestra',
          members: [
            TeamMember(id: '1', name: 'You', email: 'you@example.com', role: 'admin'),
            TeamMember(id: '2', name: 'John Smith', email: 'john@example.com', role: 'member'),
            TeamMember(id: '3', name: 'Sarah Chen', email: 'sarah@example.com', role: 'admin'),
          ],
          sharedScores: scores.isNotEmpty ? [scores[0]] : [],
          sharedSetlists: setlists.isNotEmpty ? [setlists[0]] : [],
        ),
        TeamData(
          id: '2',
          name: 'Chamber Ensemble',
          members: [
            TeamMember(id: '1', name: 'You', email: 'you@example.com', role: 'admin'),
            TeamMember(id: '4', name: 'Emma Wilson', email: 'emma@example.com', role: 'member'),
          ],
          sharedScores: scores.length >= 3 ? [scores[1], scores[2]] : [],
          sharedSetlists: [],
        ),
        TeamData(
          id: '3',
          name: 'Jazz Quartet',
          members: [
            TeamMember(id: '1', name: 'You', email: 'you@example.com', role: 'member'),
            TeamMember(id: '5', name: 'Mike Johnson', email: 'mike@example.com', role: 'admin'),
            TeamMember(id: '6', name: 'Lisa Brown', email: 'lisa@example.com', role: 'member'),
          ],
          sharedScores: scores.length >= 4 ? [scores[3]] : [],
          sharedSetlists: setlists.length >= 2 ? [setlists[1]] : [],
        ),
      ];
    }
  }
}

final teamsProvider = NotifierProvider<TeamsNotifier, List<TeamData>>(() {
  return TeamsNotifier();
});

class CurrentTeamIdNotifier extends Notifier<String> {
  @override
  String build() => '1';
  
  @override
  set state(String newState) => super.state = newState;
}

final currentTeamIdProvider = NotifierProvider<CurrentTeamIdNotifier, String>(CurrentTeamIdNotifier.new);

final currentTeamProvider = Provider<TeamData?>((ref) {
  final teams = ref.watch(teamsProvider);
  final currentTeamId = ref.watch(currentTeamIdProvider);
  return teams.firstWhere((t) => t.id == currentTeamId, orElse: () => teams.isNotEmpty ? teams[0] : TeamData(
    id: '1',
    name: 'Default Team',
    members: [],
    sharedScores: [],
    sharedSetlists: [],
  ));
});