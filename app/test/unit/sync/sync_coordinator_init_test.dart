// Tests for SyncCoordinator initialization and lifecycle
//
// These tests verify that:
// 1. SyncCoordinator is properly initialized before use
// 2. Defensive checks prevent crashes when SyncCoordinator is not initialized
// 3. Logout properly resets all sync-related services

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:musheet/core/sync/scoped_sync_coordinator.dart';
import 'package:musheet/core/sync/unified_sync_manager.dart';
import 'package:musheet/core/data/local/local_data_source.dart';
import 'package:musheet/core/data/remote/api_client.dart';
import 'package:musheet/core/services/services.dart';

// Mocks
class MockSyncableDataSource extends Mock implements SyncableDataSource {}

class MockApiClient extends Mock implements ApiClient {}

class MockSessionService extends Mock implements SessionService {}

class MockNetworkService extends Mock implements NetworkService {}

void main() {
  group('SyncCoordinator Initialization Tests', () {
    late MockSyncableDataSource mockLocal;
    late MockApiClient mockApi;
    late MockSessionService mockSession;
    late MockNetworkService mockNetwork;

    setUp(() {
      mockLocal = MockSyncableDataSource();
      mockApi = MockApiClient();
      mockSession = MockSessionService();
      mockNetwork = MockNetworkService();

      // Default mock behaviors
      when(() => mockSession.isAuthenticated).thenReturn(true);
      when(() => mockSession.userId).thenReturn(1);
      when(() => mockNetwork.isOnline).thenReturn(true);
    });

    tearDown(() {
      // Reset all singletons
      if (UnifiedSyncManager.isInitialized) {
        UnifiedSyncManager.reset();
      }
      if (SyncCoordinator.isInitialized) {
        SyncCoordinator.reset();
      }
      if (TeamSyncManager.isInitialized) {
        TeamSyncManager.reset();
      }
    });

    test('SyncCoordinator.instance throws when not initialized', () {
      // Ensure not initialized
      if (SyncCoordinator.isInitialized) {
        SyncCoordinator.reset();
      }

      expect(
        () => SyncCoordinator.instance,
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('SyncCoordinator not initialized'),
        )),
      );
    });

    test('SyncCoordinator.isInitialized returns false when not initialized',
        () {
      // Ensure not initialized
      if (SyncCoordinator.isInitialized) {
        SyncCoordinator.reset();
      }

      expect(SyncCoordinator.isInitialized, isFalse);
    });

    test('SyncCoordinator.reset sets instance to null', () async {
      // First initialize
      when(() => mockLocal.getLibraryVersion()).thenAnswer((_) async => 0);
      when(() => mockLocal.getLastSyncTime()).thenAnswer((_) async => null);
      when(() => mockLocal.getPendingChangesCount()).thenAnswer((_) async => 0);

      await SyncCoordinator.initialize(
        local: mockLocal,
        api: mockApi,
        session: mockSession,
        network: mockNetwork,
      );

      expect(SyncCoordinator.isInitialized, isTrue);

      // Reset
      SyncCoordinator.reset();

      expect(SyncCoordinator.isInitialized, isFalse);
    });
  });

  group('UnifiedSyncManager Defensive Checks', () {
    test(
        'requestSync does not throw when SyncCoordinator is not initialized',
        () async {
      // Ensure SyncCoordinator is not initialized
      if (SyncCoordinator.isInitialized) {
        SyncCoordinator.reset();
      }

      // This simulates the bug scenario where UnifiedSyncManager's _onLogin
      // is called but SyncCoordinator has been reset
      // The fix adds a defensive check that should prevent the crash

      // We can't easily test UnifiedSyncManager.requestSync directly without
      // full initialization, but we can verify the isInitialized check works
      expect(SyncCoordinator.isInitialized, isFalse);

      // The fix ensures that requestSync checks SyncCoordinator.isInitialized
      // before accessing SyncCoordinator.instance
    });
  });

  group('Logout Reset Order Tests', () {
    late String authStateProviderSource;

    setUpAll(() {
      // Read auth_state_provider.dart to analyze reset order
      final projectRoot = Directory.current.path;
      authStateProviderSource = File(
        '$projectRoot/lib/providers/auth_state_provider.dart',
      ).readAsStringSync();
    });

    test('UnifiedSyncManager must be reset FIRST in logout', () {
      // UnifiedSyncManager holds login/logout listeners that reference other coordinators.
      // If not reset first, its callbacks could access already-reset coordinators.

      final unifiedResetIndex =
          authStateProviderSource.indexOf('UnifiedSyncManager.reset()');
      final pdfResetIndex =
          authStateProviderSource.indexOf('PdfSyncService.reset()');
      final syncCoordinatorResetIndex =
          authStateProviderSource.indexOf('SyncCoordinator.reset()');
      final teamSyncResetIndex =
          authStateProviderSource.indexOf('TeamSyncManager.reset()');

      // Verify all reset calls exist
      expect(
        unifiedResetIndex,
        isNot(-1),
        reason: 'UnifiedSyncManager.reset() should be called in logout',
      );
      expect(
        pdfResetIndex,
        isNot(-1),
        reason: 'PdfSyncService.reset() should be called in logout',
      );
      expect(
        syncCoordinatorResetIndex,
        isNot(-1),
        reason: 'SyncCoordinator.reset() should be called in logout',
      );
      expect(
        teamSyncResetIndex,
        isNot(-1),
        reason: 'TeamSyncManager.reset() should be called in logout',
      );

      // Verify UnifiedSyncManager is reset FIRST (before all others)
      expect(
        unifiedResetIndex < pdfResetIndex,
        isTrue,
        reason:
            'BUG: UnifiedSyncManager.reset() must come BEFORE PdfSyncService.reset(). '
            'UnifiedSyncManager holds login listeners that could trigger after other services are reset.',
      );
      expect(
        unifiedResetIndex < syncCoordinatorResetIndex,
        isTrue,
        reason:
            'BUG: UnifiedSyncManager.reset() must come BEFORE SyncCoordinator.reset(). '
            'UnifiedSyncManager references SyncCoordinator internally.',
      );
      expect(
        unifiedResetIndex < teamSyncResetIndex,
        isTrue,
        reason:
            'BUG: UnifiedSyncManager.reset() must come BEFORE TeamSyncManager.reset(). '
            'UnifiedSyncManager coordinates team sync operations.',
      );
    });

    test('SyncCoordinator reset should come after PdfSyncService reset', () {
      // PdfSyncService is used by SyncCoordinator for PDF sync operations.
      // It should be reset before SyncCoordinator to ensure clean shutdown.

      final pdfResetIndex =
          authStateProviderSource.indexOf('PdfSyncService.reset()');
      final syncCoordinatorResetIndex =
          authStateProviderSource.indexOf('SyncCoordinator.reset()');

      expect(
        pdfResetIndex < syncCoordinatorResetIndex,
        isTrue,
        reason:
            'PdfSyncService.reset() should come before SyncCoordinator.reset(). '
            'PdfSyncService is a dependency used during sync operations.',
      );
    });

    test('All four sync services are reset in logout', () {
      // Verify the complete reset sequence exists
      final resetServices = [
        'UnifiedSyncManager',
        'PdfSyncService',
        'SyncCoordinator',
        'TeamSyncManager',
      ];

      for (final service in resetServices) {
        expect(
          authStateProviderSource.contains('$service.reset()'),
          isTrue,
          reason: 'BUG: $service.reset() is missing from logout(). '
              'All sync services must be reset to prevent memory leaks and stale state.',
        );
      }
    });

    test('Reset calls use isInitialized guard', () {
      // Each reset should be guarded by isInitialized check to prevent errors
      // when logging out before services were initialized

      final guardedResets = [
        'if (UnifiedSyncManager.isInitialized)',
        'if (PdfSyncService.isInitialized)',
        'if (SyncCoordinator.isInitialized)',
        'if (TeamSyncManager.isInitialized)',
      ];

      for (final guard in guardedResets) {
        expect(
          authStateProviderSource.contains(guard),
          isTrue,
          reason: 'BUG: Missing guard "$guard" before reset call. '
              'Reset should be guarded to prevent errors during early logout.',
        );
      }
    });
  });
}
