/// Post-Login Refresh Tests
///
/// Tests for verifying that data providers correctly refresh after login
/// when sync completes.
///
/// Bug Description:
/// - After login, Library data auto-refreshes but Team data does not
/// - User has to restart the app to see Team data
///
/// Root Cause Analysis (UPDATED):
/// - UnifiedSyncManager._getJoinedTeamIds() reads from LOCAL DATABASE
/// - On first login, local database has NO team data yet
/// - So UnifiedSyncManager only syncs Library, not Teams
/// - Team list sync happens later in TeamsStateNotifier._loadTeams()
/// - But by then, UnifiedSyncManager has already finished
/// - Team data (scores/setlists) never gets synced!
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Post-Login Refresh - Bug Detection', () {
    late String unifiedSyncManagerSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      unifiedSyncManagerSource = File(
        '$projectRoot/lib/core/sync/unified_sync_manager.dart',
      ).readAsStringSync();
    });

    test(
        'BUG DETECTION: UnifiedSyncManager reads team IDs from local DB before team list is synced',
        () {
      // The bug is in UnifiedSyncManager._getJoinedTeamIds():
      // - It reads team IDs from local database
      // - But on first login, local database has NO team data
      // - So it returns empty list
      // - Result: Only Library sync happens, Team sync is skipped

      // Check if _getJoinedTeamIds reads from local database
      final readsFromLocalDb = unifiedSyncManagerSource.contains(
              '_db.select(_db.teams)') ||
          unifiedSyncManagerSource.contains('_db.teams');

      expect(
        readsFromLocalDb,
        isTrue,
        reason:
            'BUG CONFIRMED: _getJoinedTeamIds reads from local DB, which is empty on first login',
      );

      // The fix should either:
      // 1. Sync team list BEFORE getting joinedTeamIds
      // 2. Or trigger a second sync after team list is loaded
      // 3. Or get team IDs from server instead of local DB
    });

    test(
        'BUG DETECTION: Team sync depends on local DB having team data already',
        () {
      // Check the sequence:
      // 1. UnifiedSyncManager.requestSync() is called
      // 2. _getJoinedTeamIds() reads from local DB -> returns []
      // 3. Only Library sync runs
      // 4. TeamsStateNotifier._loadTeams() syncs team LIST from server
      // 5. Now local DB has team data
      // 6. But UnifiedSyncManager has already finished!
      // 7. Team scores/setlists are NOT synced

      final hasGetJoinedTeamIds =
          unifiedSyncManagerSource.contains('_getJoinedTeamIds');
      final syncsLibraryFirst =
          unifiedSyncManagerSource.contains('SyncCoordinator.instance');

      // If both are true, there's a timing issue
      expect(
        hasGetJoinedTeamIds && syncsLibraryFirst,
        isTrue,
        reason: 'BUG: UnifiedSyncManager gets team IDs from local DB before '
            'team list is synced from server. On first login, this returns '
            'empty list, so team data never gets synced.',
      );
    });

    test('FIX VERIFICATION: Should sync team list before getting team IDs', () {
      // The fix should ensure team list is synced before getting team IDs
      // Options:
      // 1. Call teamRepo.syncTeamsFromServer() in UnifiedSyncManager before requestSync
      // 2. Or trigger a second sync after TeamsStateNotifier loads team list
      // 3. Or have UnifiedSyncManager listen for team list changes

      // Check if there's a mechanism to sync team list first
      final syncsTeamListFirst =
          unifiedSyncManagerSource.contains('syncTeamsFromServer') ||
          unifiedSyncManagerSource.contains('_syncTeamListFromServer');

      // After fix, this should be true
      expect(
        syncsTeamListFirst,
        isTrue,
        reason: 'After fix: UnifiedSyncManager should sync team list from '
            'server BEFORE calling _getJoinedTeamIds(), so team data '
            'will be synced on first login.',
      );
    });
  });

  group('Post-Login Refresh - Timing Analysis', () {
    test('Simulate login timing issue', () async {
      // Simulate the login flow to show the timing problem

      // State
      var localTeamIds = <int>[]; // Local DB is empty initially
      var librarySynced = false;
      var teamDataSynced = false;

      // Simulate _getJoinedTeamIds
      List<int> getJoinedTeamIds() => localTeamIds;

      // Simulate UnifiedSyncManager.requestSync
      Future<void> requestSync() async {
        // Get team IDs from local DB (BUG: empty on first login!)
        final teamIds = getJoinedTeamIds();

        // Sync Library
        librarySynced = true;

        // Sync Teams (but teamIds is empty!)
        for (final _ in teamIds) {
          teamDataSynced = true; // This never executes!
        }
      }

      // Simulate TeamsStateNotifier._loadTeams (happens after requestSync)
      Future<void> loadTeams() async {
        // This syncs team LIST from server
        // Simulating: await teamRepo.syncTeamsFromServer()
        localTeamIds = [1, 2, 3]; // Now we have team IDs!
      }

      // === LOGIN FLOW ===

      // Step 1: requestSync is called (from _initializeSync)
      await requestSync();

      expect(librarySynced, isTrue, reason: 'Library should be synced');
      expect(teamDataSynced, isFalse,
          reason: 'BUG: Team data NOT synced because teamIds was empty');

      // Step 2: TeamsStateNotifier loads team list
      await loadTeams();

      expect(localTeamIds.length, 3, reason: 'Now we have team IDs');
      expect(teamDataSynced, isFalse,
          reason: 'BUG: Team data still NOT synced - requestSync already finished!');

      // === THE FIX ===
      // After loading teams, we should trigger another sync
      await requestSync(); // Second sync

      expect(teamDataSynced, isTrue,
          reason: 'After fix: Team data should be synced on second pass');
    });
  });
}
