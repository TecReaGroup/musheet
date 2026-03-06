/// UnifiedSyncManager Tests
///
/// Tests for UnifiedSyncManager to verify proper team sync coordination.
/// This test file specifically checks for the bug where login does not
/// trigger team sync or UI refresh due to coordinator instance mismatch.
library;

import 'dart:io';

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
    late String authStateProviderSource;
    late String unifiedSyncManagerSource;

    setUpAll(() {
      // Read source files to analyze their structure
      final projectRoot = Directory.current.path;
      authStateProviderSource = File(
        '$projectRoot/lib/providers/auth_state_provider.dart',
      ).readAsStringSync();
      unifiedSyncManagerSource = File(
        '$projectRoot/lib/core/sync/unified_sync_manager.dart',
      ).readAsStringSync();
    });

    test(
      '_initializeSync() uses UnifiedSyncManager.requestSync for both library and team sync',
      () {
        // Verify _initializeSync() triggers unified sync (not just library sync)
        // This ensures both library AND team data are synced after login

        // Check that UnifiedSyncManager.initialize is called
        expect(
          authStateProviderSource.contains('UnifiedSyncManager.initialize'),
          isTrue,
          reason:
              'BUG DETECTED: _initializeSync() should call UnifiedSyncManager.initialize. '
              'Without UnifiedSyncManager, team sync will not be triggered after login.',
        );

        // Check that UnifiedSyncManager.requestSync is called (not just SyncCoordinator)
        expect(
          authStateProviderSource.contains('UnifiedSyncManager.instance.requestSync'),
          isTrue,
          reason:
              'BUG DETECTED: _initializeSync() should call UnifiedSyncManager.instance.requestSync(). '
              'This triggers both library AND team sync. '
              'If only SyncCoordinator.requestSync is called, teams will not sync after login.',
        );
      },
    );

    test(
      'UnifiedSyncManager._getOrCreateTeamCoordinator delegates to TeamSyncManager',
      () {
        // Verify that UnifiedSyncManager uses TeamSyncManager's coordinators
        // This ensures UI (watching TeamSyncManager) sees sync state changes

        expect(
          unifiedSyncManagerSource.contains('TeamSyncManager.instance.getCoordinator'),
          isTrue,
          reason:
              'BUG DETECTED: UnifiedSyncManager._getOrCreateTeamCoordinator() should delegate '
              'to TeamSyncManager.instance.getCoordinator(). '
              'Without this delegation, UnifiedSyncManager creates its own coordinator instances, '
              'and UI watching TeamSyncManager will never see sync state changes.',
        );
      },
    );

    test(
      'UnifiedSyncManager.getTeamCoordinator uses TeamSyncManager.getCachedCoordinator',
      () {
        // Verify synchronous access also uses the shared cache

        expect(
          unifiedSyncManagerSource.contains('TeamSyncManager.instance.getCachedCoordinator'),
          isTrue,
          reason:
              'BUG DETECTED: UnifiedSyncManager.getTeamCoordinator() should use '
              'TeamSyncManager.instance.getCachedCoordinator() for synchronous access. '
              'This ensures the same coordinator instance is returned.',
        );
      },
    );
  });

  group('Initialization Order Tests', () {
    late String authStateProviderSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      authStateProviderSource = File(
        '$projectRoot/lib/providers/auth_state_provider.dart',
      ).readAsStringSync();
    });

    test('PdfSyncService is initialized before UnifiedSyncManager', () {
      // PdfSyncService is used by sync coordinators for PDF sync
      // It should be initialized first

      final pdfInitIndex =
          authStateProviderSource.indexOf('PdfSyncService.initialize');
      final unifiedInitIndex =
          authStateProviderSource.indexOf('UnifiedSyncManager.initialize');

      expect(
        pdfInitIndex,
        isNot(-1),
        reason: 'PdfSyncService.initialize should be called in _initializeSync',
      );
      expect(
        unifiedInitIndex,
        isNot(-1),
        reason: 'UnifiedSyncManager.initialize should be called in _initializeSync',
      );

      expect(
        pdfInitIndex < unifiedInitIndex,
        isTrue,
        reason:
            'BUG: PdfSyncService.initialize must come BEFORE UnifiedSyncManager.initialize. '
            'UnifiedSyncManager triggers PDF sync after data sync completes.',
      );
    });

    test('Sync initialization has proper guards', () {
      // Each initialization should be guarded by isInitialized check

      final guards = [
        'if (!PdfSyncService.isInitialized)',
        'if (!UnifiedSyncManager.isInitialized)',
      ];

      for (final guard in guards) {
        expect(
          authStateProviderSource.contains(guard),
          isTrue,
          reason: 'BUG: Missing guard "$guard" before initialization. '
              'Double initialization should be prevented.',
        );
      }
    });
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
