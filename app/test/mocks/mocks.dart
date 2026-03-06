/// Mock classes for testing
///
/// Uses mocktail to create mock implementations of core interfaces.
library;

import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:musheet/core/data/local/local_data_source.dart';
import 'package:musheet/core/data/remote/api_client.dart';
import 'package:musheet/core/services/network_service.dart';
import 'package:musheet/core/services/session_service.dart';
import 'package:musheet/models/score.dart';
import 'package:musheet/models/setlist.dart';
import 'package:musheet/models/annotation.dart';

// ============================================================================
// Mock LocalDataSource
// ============================================================================

/// Mock implementation of LocalDataSource for testing repositories
class MockLocalDataSource extends Mock implements LocalDataSource {}

// ============================================================================
// Mock SyncableDataSource
// ============================================================================

/// Mock implementation of SyncableDataSource for testing sync coordinators
class MockSyncableDataSource extends Mock implements SyncableDataSource {}

// ============================================================================
// Mock ApiClient
// ============================================================================

/// Mock implementation of ApiClient for testing sync coordinators
class MockApiClient extends Mock implements ApiClient {}

// ============================================================================
// Mock Services
// ============================================================================

/// Mock implementation of NetworkService
class MockNetworkService extends Mock implements NetworkService {}

/// Mock implementation of SessionService
class MockSessionService extends Mock implements SessionService {}

// ============================================================================
// Fake Classes for registerFallbackValue
// ============================================================================

/// Fake Score for mocktail's any() matcher
class FakeScore extends Fake implements Score {}

/// Fake InstrumentScore for mocktail's any() matcher
class FakeInstrumentScore extends Fake implements InstrumentScore {}

/// Fake Setlist for mocktail's any() matcher
class FakeSetlist extends Fake implements Setlist {}

/// Fake Annotation for mocktail's any() matcher
class FakeAnnotation extends Fake implements Annotation {}

// ============================================================================
// Setup Helper
// ============================================================================

/// Register all fallback values for mocktail
/// Call this in setUpAll() before running tests
void registerFallbackValues() {
  registerFallbackValue(FakeScore());
  registerFallbackValue(FakeInstrumentScore());
  registerFallbackValue(FakeSetlist());
  registerFallbackValue(FakeAnnotation());
  registerFallbackValue(LocalSyncStatus.pending);
  registerFallbackValue(<Annotation>[]);
  registerFallbackValue(<String>[]);
  registerFallbackValue(<Map<String, dynamic>>[]);
}

// ============================================================================
// Mock Helpers
// ============================================================================

/// Setup default mock behaviors for LocalDataSource
extension MockLocalDataSourceSetup on MockLocalDataSource {
  void setupDefaultBehaviors() {
    // Default empty returns
    when(() => getAllScores()).thenAnswer((_) async => []);
    when(() => getAllSetlists()).thenAnswer((_) async => []);
    when(() => watchAllScores()).thenAnswer((_) => const Stream.empty());
    when(() => watchAllSetlists()).thenAnswer((_) => const Stream.empty());
    when(() => getScoreById(any())).thenAnswer((_) async => null);
    when(() => getSetlistById(any())).thenAnswer((_) async => null);

    // Default void operations
    when(() => insertScore(any(), status: any(named: 'status')))
        .thenAnswer((_) async {});
    when(() => updateScore(any(), status: any(named: 'status')))
        .thenAnswer((_) async {});
    when(() => deleteScore(any())).thenAnswer((_) async {});
    when(() => insertSetlist(any(), status: any(named: 'status')))
        .thenAnswer((_) async {});
    when(() => updateSetlist(any(), status: any(named: 'status')))
        .thenAnswer((_) async {});
    when(() => deleteSetlist(any())).thenAnswer((_) async {});
    when(() => insertInstrumentScore(any(), any())).thenAnswer((_) async {});
    when(() => updateInstrumentScore(any(), status: any(named: 'status')))
        .thenAnswer((_) async {});
    when(() => deleteInstrumentScore(any())).thenAnswer((_) async {});
    when(() => updateAnnotations(any(), any())).thenAnswer((_) async {});
  }
}

/// Setup default mock behaviors for SyncableDataSource
extension MockSyncableDataSourceSetup on MockSyncableDataSource {
  void setupDefaultBehaviors() {
    // LocalDataSource methods
    when(() => getAllScores()).thenAnswer((_) async => []);
    when(() => getAllSetlists()).thenAnswer((_) async => []);
    when(() => watchAllScores()).thenAnswer((_) => const Stream.empty());
    when(() => watchAllSetlists()).thenAnswer((_) => const Stream.empty());
    when(() => getScoreById(any())).thenAnswer((_) async => null);
    when(() => getSetlistById(any())).thenAnswer((_) async => null);

    when(() => insertScore(any(), status: any(named: 'status')))
        .thenAnswer((_) async {});
    when(() => updateScore(any(), status: any(named: 'status')))
        .thenAnswer((_) async {});
    when(() => deleteScore(any())).thenAnswer((_) async {});
    when(() => insertSetlist(any(), status: any(named: 'status')))
        .thenAnswer((_) async {});
    when(() => updateSetlist(any(), status: any(named: 'status')))
        .thenAnswer((_) async {});
    when(() => deleteSetlist(any())).thenAnswer((_) async {});
    when(() => insertInstrumentScore(any(), any())).thenAnswer((_) async {});
    when(() => updateInstrumentScore(any(), status: any(named: 'status')))
        .thenAnswer((_) async {});
    when(() => deleteInstrumentScore(any())).thenAnswer((_) async {});
    when(() => updateAnnotations(any(), any())).thenAnswer((_) async {});

    // Sync-specific methods
    when(() => getLibraryVersion()).thenAnswer((_) async => 0);
    when(() => setLibraryVersion(any())).thenAnswer((_) async {});
    when(() => getLastSyncTime()).thenAnswer((_) async => null);
    when(() => setLastSyncTime(any())).thenAnswer((_) async {});
    when(() => getPendingChangesCount()).thenAnswer((_) async => 0);

    when(() => getPendingScores()).thenAnswer((_) async => []);
    when(() => getPendingInstrumentScores()).thenAnswer((_) async => []);
    when(() => getPendingSetlists()).thenAnswer((_) async => []);
    when(() => getPendingSetlistScores()).thenAnswer((_) async => []);
    when(() => getPendingDeletes()).thenAnswer((_) async => []);
    when(() => getPendingPdfUploads()).thenAnswer((_) async => []);

    when(() => applyPulledData(
          scores: any(named: 'scores'),
          instrumentScores: any(named: 'instrumentScores'),
          setlists: any(named: 'setlists'),
          newLibraryVersion: any(named: 'newLibraryVersion'),
          setlistScores: any(named: 'setlistScores'),
        )).thenAnswer((_) async {});

    when(() => markAsSynced(any(), any())).thenAnswer((_) async {});
    when(() => updateServerIds(any())).thenAnswer((_) async {});
    when(() => markPdfAsSynced(any(), any())).thenAnswer((_) async {});
    when(() => cleanupSyncedDeletes()).thenAnswer((_) async {});
    when(() => markPendingDeletesAsSynced()).thenAnswer((_) async {});
  }
}

/// Setup default mock behaviors for NetworkService
extension MockNetworkServiceSetup on MockNetworkService {
  void setupDefaultOnline() {
    when(() => isOnline).thenReturn(true);
    when(() => state).thenReturn(const NetworkState(
      status: NetworkStatus.online,
    ));
    when(() => stateStream).thenAnswer(
      (_) => Stream.value(const NetworkState(status: NetworkStatus.online)),
    );
    when(() => onOnline(any())).thenReturn(null);
    when(() => onOffline(any())).thenReturn(null);
    when(() => removeOnOnline(any())).thenReturn(null);
    when(() => removeOnOffline(any())).thenReturn(null);
  }

  void setupOffline() {
    when(() => isOnline).thenReturn(false);
    when(() => state).thenReturn(const NetworkState(
      status: NetworkStatus.offline,
    ));
    when(() => stateStream).thenAnswer(
      (_) => Stream.value(const NetworkState(status: NetworkStatus.offline)),
    );
  }
}

/// Setup default mock behaviors for SessionService
extension MockSessionServiceSetup on MockSessionService {
  void setupAuthenticated({int userId = 1}) {
    when(() => isAuthenticated).thenReturn(true);
    when(() => this.userId).thenReturn(userId);
    when(() => token).thenReturn('test_token');
    when(() => state).thenReturn(SessionState(
      status: SessionStatus.authenticated,
      userId: userId,
      token: 'test_token',
    ));
    when(() => stateStream).thenAnswer(
      (_) => Stream.value(SessionState(
        status: SessionStatus.authenticated,
        userId: userId,
        token: 'test_token',
      )),
    );
  }

  void setupUnauthenticated() {
    when(() => isAuthenticated).thenReturn(false);
    when(() => userId).thenReturn(null);
    when(() => token).thenReturn(null);
    when(() => state).thenReturn(const SessionState(
      status: SessionStatus.unauthenticated,
    ));
    when(() => stateStream).thenAnswer(
      (_) => Stream.value(const SessionState(
        status: SessionStatus.unauthenticated,
      )),
    );
  }
}
