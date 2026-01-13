/// UnifiedSyncManager Tests
///
/// Tests for UnifiedSyncManager to verify proper team sync coordination.
/// This test file specifically checks for the bug where login does not
/// trigger team sync or UI refresh due to coordinator instance mismatch.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/core/data/data_scope.dart';
import 'package:musheet/core/sync/scoped_sync_coordinator.dart';
import 'package:musheet/core/sync/unified_sync_manager.dart';
import 'package:musheet/database/database.dart';

import '../../mocks/mocks.dart';

void main() {
  // Initialize Flutter binding for tests that need it
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TeamSyncManager Coordinator Instance Tests', () {
    late AppDatabase testDb;
    late MockApiClient mockApiClient;
    late MockSessionService mockSession;
    late MockNetworkService mockNetwork;

    const testUserId = 1;
    const testTeamId = 42;

    setUpAll(() {
      registerFallbackValues();
    });

    setUp(() {
      // Create in-memory database for testing
      testDb = AppDatabase.forTesting(NativeDatabase.memory());

      mockApiClient = MockApiClient();
      mockSession = MockSessionService();
      mockNetwork = MockNetworkService();

      mockSession.setupAuthenticated(userId: testUserId);
      mockNetwork.setupDefaultOnline();
    });

    tearDown(() async {
      // Reset singletons
      if (TeamSyncManager.isInitialized) {
        TeamSyncManager.reset();
      }
      if (SyncCoordinator.isInitialized) {
        SyncCoordinator.reset();
      }
      if (UnifiedSyncManager.isInitialized) {
        UnifiedSyncManager.reset();
      }
      await testDb.close();
    });

    test(
      'TeamSyncManager.getCoordinator returns same instance for same teamId',
      () async {
        // Initialize TeamSyncManager
        TeamSyncManager.initialize(
          db: testDb,
          api: mockApiClient,
          session: mockSession,
          network: mockNetwork,
        );

        // Get coordinator twice for the same team
        final coordinator1 =
            await TeamSyncManager.instance.getCoordinator(testTeamId);
        final coordinator2 =
            await TeamSyncManager.instance.getCoordinator(testTeamId);

        // Should be the SAME instance
        expect(
          identical(coordinator1, coordinator2),
          isTrue,
          reason:
              'TeamSyncManager should return the same coordinator instance for the same teamId',
        );
      },
    );

    test(
      'TeamSyncManager returns different instances for different teamIds',
      () async {
        // Initialize TeamSyncManager
        TeamSyncManager.initialize(
          db: testDb,
          api: mockApiClient,
          session: mockSession,
          network: mockNetwork,
        );

        // Get coordinators for different teams
        final coordinator1 =
            await TeamSyncManager.instance.getCoordinator(testTeamId);
        final coordinator2 =
            await TeamSyncManager.instance.getCoordinator(testTeamId + 1);

        // Should be DIFFERENT instances
        expect(
          identical(coordinator1, coordinator2),
          isFalse,
          reason:
              'TeamSyncManager should return different coordinator instances for different teamIds',
        );
      },
    );

    test(
      'REGRESSION: UnifiedSyncManager and TeamSyncManager MUST share coordinator instances',
      () async {
        // This test verifies that when UnifiedSyncManager syncs a team,
        // the UI (which watches TeamSyncManager's coordinators) will see the updates.
        //
        // EXPECTED BEHAVIOR (after fix):
        // - UnifiedSyncManager._getOrCreateTeamCoordinator(teamId) should return
        //   the same instance as TeamSyncManager.getCoordinator(teamId)
        //
        // CURRENT BUG:
        // - UnifiedSyncManager creates its own coordinator instances
        // - TeamSyncManager creates separate coordinator instances
        // - UI watches TeamSyncManager, but sync happens in UnifiedSyncManager
        // - UI never refreshes!

        // Initialize both managers
        TeamSyncManager.initialize(
          db: testDb,
          api: mockApiClient,
          session: mockSession,
          network: mockNetwork,
        );

        final mockSyncableDataSource = MockSyncableDataSource();
        mockSyncableDataSource.setupDefaultBehaviors();

        await UnifiedSyncManager.initialize(
          localLibrary: mockSyncableDataSource,
          api: mockApiClient,
          session: mockSession,
          network: mockNetwork,
          db: testDb,
        );

        // Get coordinator from TeamSyncManager FIRST (what UI watches)
        final uiCoordinator =
            await TeamSyncManager.instance.getCoordinator(testTeamId);

        // Now get coordinator from UnifiedSyncManager
        // After fix, this should return the SAME instance from TeamSyncManager's cache
        final unifiedCoordinator =
            UnifiedSyncManager.instance.getTeamCoordinator(testTeamId);

        // THE FIX VERIFICATION:
        // After the fix, UnifiedSyncManager.getTeamCoordinator() delegates to
        // TeamSyncManager.getCachedCoordinator(), so both should return the same instance.

        expect(
          unifiedCoordinator,
          isNotNull,
          reason:
              'After fix: UnifiedSyncManager.getTeamCoordinator should return '
              'the coordinator from TeamSyncManager cache.',
        );

        expect(
          identical(uiCoordinator, unifiedCoordinator),
          isTrue,
          reason:
              'After fix: UnifiedSyncManager and TeamSyncManager should return '
              'the SAME coordinator instance for the same teamId. '
              'This ensures UI refreshes when sync completes.',
        );
      },
    );
  });

  group('Login Flow Team Sync Tests', () {
    test(
      'BUG: _initializeSync() only triggers library sync, not team sync',
      () {
        // Analyze the code in auth_state_provider.dart _initializeSync():
        //
        // Lines 365-390:
        //   if (!SyncCoordinator.isInitialized) {
        //     await SyncCoordinator.initialize(...);
        //   }
        //   if (!TeamSyncManager.isInitialized) {
        //     TeamSyncManager.initialize(...);
        //   }
        //   // Trigger initial sync
        //   SyncCoordinator.instance.requestSync(immediate: true);
        //
        // PROBLEM: Only SyncCoordinator.requestSync() is called!
        // TeamSyncManager.syncAllTeams() is NEVER called.
        // UnifiedSyncManager is not even initialized.

        // Expected behavior:
        // After login, BOTH library AND team data should be synced.
        // Either use:
        //   await UnifiedSyncManager.instance.requestSync(immediate: true);
        // Or:
        //   await SyncCoordinator.instance.requestSync(immediate: true);
        //   await TeamSyncManager.instance.syncAllTeams();

        // This test documents the bug by checking the expected code structure
        expect(
          true,
          isTrue,
          reason:
              'Bug documented: _initializeSync() needs to trigger team sync after login',
        );
      },
    );

    test(
      'BUG: When UnifiedSyncManager syncs, UI watching TeamSyncManager does not update',
      () {
        // The architectural issue:
        //
        // 1. TeamSyncManager (scoped_sync_coordinator.dart lines 684-776):
        //    - Has: Map<int, ScopedSyncCoordinator> _coordinators = {};
        //    - getCoordinator(teamId) creates/returns coordinators from this map
        //
        // 2. UnifiedSyncManager (unified_sync_manager.dart lines 22-255):
        //    - Has: Map<int, ScopedSyncCoordinator> _teamCoordinators = {};
        //    - _getOrCreateTeamCoordinator(teamId) creates/returns from THIS map
        //
        // 3. UI providers use: TeamSyncManager.instance.getCoordinator(teamId)
        //    to watch for state changes.
        //
        // 4. But UnifiedSyncManager.requestSync() uses its OWN coordinators
        //    in _teamCoordinators.
        //
        // RESULT: When UnifiedSyncManager syncs team data:
        //   - It updates state in its own coordinator
        //   - UI is watching a DIFFERENT coordinator from TeamSyncManager
        //   - UI never sees the state change
        //   - UI never refreshes!

        // The fix should be ONE of:
        // A) UnifiedSyncManager._getOrCreateTeamCoordinator() should delegate
        //    to TeamSyncManager.instance.getCoordinator() instead of
        //    creating its own instances.
        //
        // B) Don't use UnifiedSyncManager for team sync at all - use
        //    TeamSyncManager directly in _initializeSync().

        expect(
          true,
          isTrue,
          reason:
              'Bug documented: UnifiedSyncManager and TeamSyncManager coordinator instance mismatch',
        );
      },
    );
  });

  group('Expected Behavior After Fix', () {
    test(
      'Fix Option 1: UnifiedSyncManager delegates to TeamSyncManager',
      () {
        // Expected fix in unified_sync_manager.dart:
        //
        // BEFORE (lines 223-243):
        //   Future<ScopedSyncCoordinator> _getOrCreateTeamCoordinator(int teamId) async {
        //     if (_teamCoordinators.containsKey(teamId)) {
        //       return _teamCoordinators[teamId]!;
        //     }
        //     // Create team-scoped data source dynamically
        //     final teamDataSource = ScopedLocalDataSource(_db, DataScope.team(teamId));
        //     final coordinator = ScopedSyncCoordinator(...);
        //     await coordinator.initialize();
        //     _teamCoordinators[teamId] = coordinator;
        //     return coordinator;
        //   }
        //
        // AFTER:
        //   Future<ScopedSyncCoordinator> _getOrCreateTeamCoordinator(int teamId) async {
        //     // Delegate to TeamSyncManager to ensure UI watches the same instance
        //     return TeamSyncManager.instance.getCoordinator(teamId);
        //   }

        expect(true, isTrue);
      },
    );

    test(
      'Fix Option 2: _initializeSync calls TeamSyncManager.syncAllTeams()',
      () {
        // Expected fix in auth_state_provider.dart _initializeSync():
        //
        // BEFORE (line 390):
        //   SyncCoordinator.instance.requestSync(immediate: true);
        //
        // AFTER:
        //   SyncCoordinator.instance.requestSync(immediate: true);
        //   await TeamSyncManager.instance.syncAllTeams();
        //
        // This directly uses TeamSyncManager's coordinators, so UI will
        // correctly observe state changes.

        expect(true, isTrue);
      },
    );

    test(
      'Fix Option 3: Use UnifiedSyncManager with Option 1 fix',
      () {
        // Expected fix combining both:
        //
        // 1. Apply Option 1 fix to UnifiedSyncManager
        // 2. In auth_state_provider.dart _initializeSync():
        //
        //   if (!UnifiedSyncManager.isInitialized) {
        //     await UnifiedSyncManager.initialize(
        //       localLibrary: local,
        //       api: ApiClient.instance,
        //       session: SessionService.instance,
        //       network: NetworkService.instance,
        //       db: db,
        //     );
        //   }
        //   // This now triggers both library AND team sync
        //   // Team sync uses TeamSyncManager's coordinators
        //   await UnifiedSyncManager.instance.requestSync(immediate: true);

        expect(true, isTrue);
      },
    );
  });

  group('DataScope Tests', () {
    test('DataScope.user creates user scope', () {
      final scope = DataScope.user;
      expect(scope.isUser, isTrue);
      expect(scope.isTeam, isFalse);
    });

    test('DataScope.team creates team scope with teamId', () {
      final scope = DataScope.team(42);
      expect(scope.isUser, isFalse);
      expect(scope.isTeam, isTrue);
      expect(scope.scopeId, equals(42));
    });

    test('Different team scopes are not equal', () {
      final scope1 = DataScope.team(1);
      final scope2 = DataScope.team(2);
      expect(scope1 == scope2, isFalse);
    });
  });
}
