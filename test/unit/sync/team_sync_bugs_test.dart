/// Team Sync Bug Detection Tests
///
/// Tests for known bugs in team synchronization:
///
/// BUG 1: Team content not synced after adding team
/// - When a new team is added on server, app syncs team list
/// - But team content (scores/setlists) is not synced
/// - Root cause: TeamsStateNotifier only syncs team list, doesn't trigger data sync
///
/// BUG 2: Offline status after removing user from team
/// - When user is removed from team on server, app shows "offline"
/// - Root cause: NotTeamMemberException not properly handled
/// - Should remove stale team data instead of marking disconnected
///
/// BUG 3: Empty team data after user removed and re-added
/// - User is removed from team, then re-added on server
/// - Local team data is cleared when removed
/// - But local version number is NOT reset
/// - Pull uses old version, server returns 0 changes
/// - Fix: Reset version to 0 when local data is empty but version > 0
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BUG 1: Team content not synced after adding team [Source Analysis]', () {
    late String coreProvidersSource;
    late String teamRepositorySource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      coreProvidersSource = File(
        '$projectRoot/lib/providers/core_providers.dart',
      ).readAsStringSync();
      teamRepositorySource = File(
        '$projectRoot/lib/core/repositories/team_repository.dart',
      ).readAsStringSync();
    });

    test('teamRepositoryProvider should wire onTeamDataChanged to trigger team sync', () {
      // The callback chain for new team data sync:
      // 1. TeamRepository.syncTeamsFromServer detects new teams
      // 2. Calls onTeamDataChanged?.call(teamId) for each new team
      // 3. teamRepositoryProvider wires onTeamDataChanged to UnifiedSyncManager.requestTeamSync
      // This triggers the team's content to be synced

      // Check if teamRepositoryProvider wires up the callback
      final wiresCallback = coreProvidersSource.contains('repo.onTeamDataChanged') &&
          coreProvidersSource.contains('requestTeamSync');

      expect(
        wiresCallback,
        isTrue,
        reason: 'BUG DETECTED: teamRepositoryProvider does not wire onTeamDataChanged callback. '
            'After syncing team list, each new team\'s scores/setlists should be synced via '
            'UnifiedSyncManager.requestTeamSync callback.',
      );
    });

    test('TeamRepository.syncTeamsFromServer should notify about new teams', () {
      // After syncing teams, should trigger data sync for new teams

      // Should have callback to notify about data changes
      final hasDataChangedCallback = teamRepositorySource.contains('onTeamDataChanged?.call');

      expect(
        hasDataChangedCallback,
        isTrue,
        reason: 'TeamRepository.syncTeamsFromServer should call '
            'onTeamDataChanged callback for new teams.',
      );
    });

    test('TeamRepository.syncTeamsFromServer should remove stale teams', () {
      // Should detect and remove local teams that user was removed from

      final removesStaleTeams = teamRepositorySource.contains('removedTeamIds') &&
          teamRepositorySource.contains('_deleteTeamLocally');

      expect(
        removesStaleTeams,
        isTrue,
        reason: 'TeamRepository.syncTeamsFromServer should remove stale local teams '
            'that user was removed from on server.',
      );
    });
  });

  group('BUG 2: Offline status after removing user from team [Source Analysis]', () {
    late String networkErrorsSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      networkErrorsSource = File(
        '$projectRoot/lib/core/network/errors.dart',
      ).readAsStringSync();
    });

    test('NetworkError.fromException should recognize NOT_MEMBER as forbidden', () {
      // Server throws NotTeamMemberException with message "Not a team member"
      // This should be classified as forbidden (403), not unknown

      // Should recognize "Not a team member" or "NOT_MEMBER" as forbidden
      final recognizesNotMember = networkErrorsSource.contains('Not a team member') ||
          networkErrorsSource.contains('NOT_MEMBER') ||
          networkErrorsSource.contains('not a member');

      expect(
        recognizesNotMember,
        isTrue,
        reason: 'BUG DETECTED: NetworkError.fromException does not recognize '
            '"Not a team member" as forbidden error. Server returns this when user '
            'is removed from team, but it\'s classified as unknown error.',
      );
    });

    test('shouldMarkDisconnected should be false for forbidden errors', () {
      // Forbidden errors are business logic errors, NOT connectivity issues
      // They should NOT mark the service as disconnected

      // Check the shouldMarkDisconnected getter logic
      // It should only return true for network and serverError types
      final correctLogic = networkErrorsSource.contains(
          'type == NetworkErrorType.network || type == NetworkErrorType.serverError');

      expect(
        correctLogic,
        isTrue,
        reason: 'shouldMarkDisconnected should only return true for network/serverError. '
            'Forbidden (403) errors should NOT trigger service disconnection.',
      );
    });
  });

  group('BUG 2b: Team removal detection [Source Analysis]', () {
    late String unifiedSyncManagerSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      unifiedSyncManagerSource = File(
        '$projectRoot/lib/core/sync/unified_sync_manager.dart',
      ).readAsStringSync();
    });

    test('UnifiedSyncManager should detect and remove teams user was removed from', () {
      // When syncing team list from server, should compare with local teams
      // Teams in local but not in server = user was removed
      // Those teams should be deleted from local database

      // Should detect removed teams and delete them
      final detectsRemovedTeams = unifiedSyncManagerSource.contains('removedTeamIds') &&
          unifiedSyncManagerSource.contains('_deleteTeamLocally');

      expect(
        detectsRemovedTeams,
        isTrue,
        reason: '_syncTeamListFromServer should detect and remove teams '
            'user was removed from.',
      );
    });

    test('UnifiedSyncManager should remove stale sync coordinators', () {
      // When a team is removed, its sync coordinator should also be removed

      final removesSyncCoordinator = unifiedSyncManagerSource.contains('removeCoordinator');

      expect(
        removesSyncCoordinator,
        isTrue,
        reason: 'UnifiedSyncManager should call TeamSyncManager.removeCoordinator '
            'when a team is removed.',
      );
    });
  });

  group('Verification: Current architecture correctness', () {
    late String networkErrorsSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      networkErrorsSource = File(
        '$projectRoot/lib/core/network/errors.dart',
      ).readAsStringSync();
    });

    test('NetworkError.shouldMarkDisconnected excludes business logic errors', () {
      // Verify the correct implementation
      // shouldMarkDisconnected should ONLY include network and serverError
      // Should NOT include: unauthorized, forbidden, notFound, conflict, badRequest

      final getter = networkErrorsSource.contains(
          'bool get shouldMarkDisconnected =>');
      expect(getter, isTrue, reason: 'shouldMarkDisconnected getter should exist');

      // The current implementation is:
      // type == NetworkErrorType.network || type == NetworkErrorType.serverError
      // This is CORRECT - it does NOT include forbidden

      final correctImplementation = networkErrorsSource.contains(
          'type == NetworkErrorType.network || type == NetworkErrorType.serverError');

      expect(
        correctImplementation,
        isTrue,
        reason: 'shouldMarkDisconnected is correctly implemented - '
            'only network and serverError trigger disconnection. '
            'The actual bug is that NotTeamMemberException is not recognized as forbidden.',
      );
    });
  });

  group('BUG 3: Empty team data after user removed and re-added [Source Analysis]', () {
    late String scopedSyncCoordinatorSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      scopedSyncCoordinatorSource = File(
        '$projectRoot/lib/core/sync/scoped_sync_coordinator.dart',
      ).readAsStringSync();
    });

    test('loadSyncState should reset version when team data is empty', () {
      // When user is removed from team, local data is cleared
      // But version number stays at the old value (e.g., 51)
      // When user is re-added, pull uses version=51, server returns 0 changes
      // Fix: Detect empty data + version > 0 and reset to 0

      final detectsEmptyTeamData = scopedSyncCoordinatorSource.contains('scores.isEmpty') &&
          scopedSyncCoordinatorSource.contains('setlists.isEmpty') &&
          scopedSyncCoordinatorSource.contains('setLibraryVersion(0)');

      expect(
        detectsEmptyTeamData,
        isTrue,
        reason: 'BUG 3 FIX VERIFIED: loadSyncState detects empty team data '
            'with non-zero version and resets to 0 for full sync.',
      );
    });

    test('version reset only applies to team scope, not user scope', () {
      // User scope should NOT have version reset logic
      // Only team scope needs this (user was removed and re-added)

      final teamScopeOnly = scopedSyncCoordinatorSource.contains('!scope.isUser');

      expect(
        teamScopeOnly,
        isTrue,
        reason: 'Version reset should only apply to team scope, not user scope.',
      );
    });
  });
}
