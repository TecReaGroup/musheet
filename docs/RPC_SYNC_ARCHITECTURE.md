# MuSheet RPC & Sync Architecture Refactoring

## Overview

This document describes the complete refactoring of the RPC communication layer and data synchronization logic for MuSheet. The refactoring addresses critical architectural defects in the original implementation and introduces a robust, type-safe, offline-first sync system.

## Table of Contents

1. [Architecture Comparison](#architecture-comparison)
2. [New RPC Layer](#new-rpc-layer)
3. [New Sync Layer](#new-sync-layer)
4. [Migration Guide](#migration-guide)
5. [API Reference](#api-reference)

---

## Architecture Comparison

### Before: Original Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Flutter App                            │
├─────────────────────────────────────────────────────────────┤
│  Providers (ScoresNotifier, SetlistsNotifier)               │
│      ↓                                                       │
│  BackendService (Singleton)                                  │
│      - Simple ApiResult<T> wrapper                           │
│      - No interceptors                                       │
│      - No retry logic                                        │
│      - Basic error handling                                  │
│      ↓                                                       │
│  SyncService (Singleton)                                     │
│      - Simple boolean _isSyncing flag                        │
│      - No state machine                                      │
│      - No operation queue                                    │
│      - Basic conflict detection                              │
│      ↓                                                       │
│  Serverpod Client (Direct access)                            │
└─────────────────────────────────────────────────────────────┘
```

**Problems:**
| Issue | Impact | Severity |
|-------|--------|----------|
| No unified error codes | Inconsistent error handling across app | High |
| No request interceptors | Cannot add logging, auth refresh, or retry centrally | High |
| Race conditions | `_isSyncing` flag not thread-safe | Critical |
| No offline queue | Failed operations are lost | Critical |
| No sync state machine | UI cannot accurately reflect sync state | Medium |
| Simple UUID generator | Can produce collisions under load | Medium |
| No idempotency | Duplicate operations can create duplicate records | High |
| No connection management | No heartbeat, no reconnection logic | Medium |

### After: Refactored Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Flutter App                            │
├─────────────────────────────────────────────────────────────┤
│  Providers (ScoresNotifier, SetlistsNotifier)               │
│      ↓                                                       │
│  SyncServiceV2                                               │
│      ├── SyncStateMachine (explicit state transitions)       │
│      ├── OperationQueue (persistent, prioritized)            │
│      ├── ConflictResolver (CRDT support)                     │
│      └── RpcClient                                           │
│              ├── InterceptorChain                            │
│              │       ├── LoggingInterceptor                  │
│              │       ├── AuthInterceptor                     │
│              │       ├── RetryInterceptor                    │
│              │       ├── TimeoutInterceptor                  │
│              │       └── CacheInterceptor                    │
│              ├── ConnectionManager (heartbeat, reconnect)    │
│              └── Serverpod Client                            │
└─────────────────────────────────────────────────────────────┘
```

---

## New RPC Layer

### RPC Protocol (`lib/rpc/rpc_protocol.dart`)

Defines the unified protocol for all RPC communication:

#### Error Codes

```dart
enum RpcErrorCode {
  // Network errors (1xxx)
  networkUnavailable(1001),
  connectionTimeout(1002),

  // Auth errors (2xxx)
  authenticationRequired(2001),
  tokenExpired(2002),

  // Sync errors (5xxx)
  syncConflict(5001),
  versionMismatch(5002),
  // ...
}
```

#### Request/Response Wrappers

```dart
// Type-safe request with metadata
class RpcRequest<T> {
  final String endpoint;
  final String method;
  final T payload;
  final String requestId;  // For tracing
  final Duration? timeout;
  final int retryCount;
}

// Response with error handling
class RpcResponse<T> {
  final T? data;
  final RpcError? error;
  final Duration latency;

  bool get isSuccess => error == null && data != null;
  bool get isRetryable => error?.isRetryable ?? false;
}
```

### Interceptor Chain (`lib/rpc/rpc_interceptors.dart`)

Provides middleware capabilities:

```dart
abstract class RpcInterceptor {
  int get priority;  // Lower = earlier execution

  Future<RpcRequest<T>> onRequest<T>(RpcRequest<T> request);
  Future<RpcResponse<T>> onResponse<T>(RpcResponse<T> response);
  Future<RpcResponse<T>> onError<T>(RpcError error, RpcRequest<T> request);
}
```

**Built-in Interceptors:**

| Interceptor | Priority | Purpose |
|-------------|----------|---------|
| MetricsInterceptor | 1 | Collect performance metrics |
| TimeoutInterceptor | 5 | Set default timeouts |
| LoggingInterceptor | 10 | Debug logging |
| CacheInterceptor | 15 | Response caching |
| AuthInterceptor | 20 | Token management |
| RetryInterceptor | 30 | Exponential backoff retry |

### RPC Client (`lib/rpc/rpc_client.dart`)

Unified client with connection management:

```dart
class RpcClient {
  // Connection management
  Stream<ConnectionStatus> get connectionStatusStream;
  Future<RpcResponse<bool>> connect();

  // Auth operations
  Future<RpcResponse<AuthResultData>> login({...});
  Future<RpcResponse<bool>> logout();

  // Data operations
  Future<RpcResponse<List<Score>>> getScores({DateTime? since});
  Future<RpcResponse<ScoreSyncResult>> upsertScore(Score score);

  // Metrics
  Map<String, Map<String, dynamic>>? get metrics;
}
```

**Features:**
- Automatic heartbeat with configurable interval
- Connection state tracking (disconnected → connecting → connected → reconnecting)
- Automatic reconnection with exponential backoff
- Centralized auth token management

---

## New Sync Layer

### Sync State Machine (`lib/sync/sync_state_machine.dart`)

Explicit state management with well-defined transitions:

```
                    ┌─────────────────┐
                    │      IDLE       │
                    └────────┬────────┘
                             │ syncRequested
                             ▼
                    ┌─────────────────┐
        ┌──────────→│    SYNCING      │←──────────┐
        │           │                 │           │
        │           │  - initializing │           │
        │           │  - pushing      │           │
        │           │  - pulling      │           │
        │           │  - merging      │           │
        │           │  - syncingFiles │           │
        │           └────────┬────────┘           │
        │                    │                    │
        │        ┌───────────┼───────────┐        │
        │        │           │           │        │
        │        ▼           ▼           ▼        │
        │  ┌──────────┐ ┌──────────┐ ┌──────────┐ │
        │  │ CONFLICT │ │  ERROR   │ │ WAITING  │ │
        │  │          │ │          │ │ NETWORK  │ │
        │  └────┬─────┘ └────┬─────┘ └────┬─────┘ │
        │       │            │            │       │
        │       │ resolved   │ retry      │ netOk │
        └───────┴────────────┴────────────┴───────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   COMPLETED     │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │      IDLE       │
                    └─────────────────┘
```

**Usage:**
```dart
final stateMachine = SyncStateMachine();

// Listen to state changes
stateMachine.stateStream.listen((state) {
  print('Sync state: ${state.statusMessage}');
  print('Progress: ${(state.progress * 100).toInt()}%');
});

// Trigger sync
stateMachine.processEvent(SyncEvent.syncRequested);

// Update progress
stateMachine.updatePhase(SyncingPhase.pushing);
stateMachine.incrementCompleted();
```

### Operation Queue (`lib/sync/operation_queue.dart`)

Persistent queue for offline-first sync:

```dart
class OperationQueue {
  Future<String> enqueue(SyncOperation operation, {
    OperationPriority priority = OperationPriority.normal,
    List<String> dependsOn = const [],
  });

  QueuedOperation? getNext();  // Get next executable operation
  List<QueuedOperation> getPending();

  Future<void> markStarted(String operationId);
  Future<void> markCompleted(String operationId);
  Future<void> markFailed(String operationId, String error);

  Future<int> retryFailed();  // Retry all failed operations
  Future<int> prune();  // Remove completed operations
}
```

**Features:**
- **Idempotency**: Duplicate operations are ignored via idempotency keys
- **Priority**: Critical operations (deletes) processed first
- **Dependencies**: Operations can depend on others
- **Persistence**: Queue survives app restarts
- **Batch operations**: Efficient bulk enqueue

### Conflict Resolver (`lib/sync/conflict_resolver.dart`)

Intelligent conflict resolution:

```dart
enum ConflictResolutionStrategy {
  keepLocal,      // Overwrite server
  keepServer,     // Overwrite local
  keepBoth,       // Create duplicate
  merge,          // CRDT-based merge
  lastWriteWins,  // Use timestamp
  manual,         // User decides
}
```

**Resolution Flow:**
1. Detect conflict type (data, delete, metadata)
2. Apply entity-specific default strategy
3. If manual, prompt user via callback
4. Apply resolved data

**Vector Clock Support:**
```dart
final clock = VectorClock({'device1': 3, 'device2': 2});
clock.increment('device1');

final comparison = clock1.compareTo(clock2);
// concurrent → conflict requires resolution
// before/after → clear winner
```

### Sync Service V2 (`lib/sync/sync_service_v2.dart`)

Orchestrates all sync components:

```dart
class SyncServiceV2 {
  // State
  SyncState get currentState;
  Stream<SyncState> get stateStream;

  // Background sync
  Future<void> startBackgroundSync();
  void stopBackgroundSync();

  // Manual sync
  Future<SyncResult> syncNow();

  // Queue changes
  Future<void> queueChange({
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    required int version,
  });

  // Conflict resolution
  Future<void> resolveConflict(
    SyncConflict conflict,
    ConflictResolutionStrategy strategy,
  );

  // PDF sync
  Future<String?> downloadPdf(String instrumentScoreId);
}
```

**Sync Algorithm:**

```
1. ACQUIRE LOCK (prevent concurrent syncs)
2. PUSH PHASE
   a. Get pending scores from local DB
   b. For each score:
      - Convert to server format
      - Call upsertScore
      - Handle conflict or update local with server ID
   c. Push instrument scores for synced scores
   d. Push pending setlists
   e. Push pending PDFs

3. PULL PHASE
   a. Get lastSyncAt timestamp
   b. Fetch scores updated since lastSyncAt
   c. For each server score:
      - Find local by serverId
      - If new: create local record
      - If exists: compare versions, merge if needed
   d. Pull instrument scores for each score
   e. Pull setlists

4. FILE SYNC PHASE
   a. Upload PDFs marked as pending
   b. Download PDFs on-demand

5. SAVE SYNC TIME
6. RELEASE LOCK
```

---

## Migration Guide

### Step 1: Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  uuid: ^4.0.0
```

### Step 2: Update Initialization

**Before:**
```dart
void main() async {
  BackendService.initialize(baseUrl: 'http://localhost:8080');
  SyncService.initialize(
    db: AppDatabase(),
    backend: BackendService.instance,
  );
}
```

**After:**
```dart
void main() async {
  // Initialize RPC client
  RpcClient.initialize(RpcClientConfig(
    baseUrl: 'http://localhost:8080',
    enableLogging: kDebugMode,
    heartbeatInterval: const Duration(seconds: 30),
  ));

  // Connect and verify
  await RpcClient.instance.connect();

  // Initialize Sync Service
  await SyncServiceV2.initialize(
    db: AppDatabase(),
    rpc: RpcClient.instance,
    config: const SyncConfig(
      periodicSyncInterval: Duration(minutes: 5),
      autoSyncOnNetworkRestore: true,
    ),
  );
}
```

### Step 3: Update Provider Usage

**Before:**
```dart
Future<void> addScore(Score score) async {
  await _db.insertScore(score);
  state = [...state, score];
  ref.read(syncServiceProvider).syncScore(score.id);
}
```

**After:**
```dart
Future<void> addScore(Score score) async {
  // Insert with pending status
  final scoreWithSync = score.copyWith(
    syncStatus: 'pending',
    version: 1,
  );
  await _db.insertScore(scoreWithSync);
  state = [...state, scoreWithSync];

  // Mark for sync (will be picked up by background sync)
  await SyncServiceV2.instance.markModified(
    entityType: SyncEntityType.score,
    entityId: score.id,
    newVersion: 1,
  );
}
```

### Step 4: Handle Sync State in UI

```dart
class SyncIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<SyncState>(
      stream: SyncServiceV2.instance.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? SyncServiceV2.instance.currentState;

        return Column(
          children: [
            if (state.isSyncing)
              LinearProgressIndicator(value: state.progress),
            Text(state.statusMessage),
            if (state.hasConflicts)
              TextButton(
                onPressed: () => _showConflictDialog(context),
                child: Text('Resolve ${state.conflictCount} conflicts'),
              ),
          ],
        );
      },
    );
  }
}
```

---

## API Reference

### RpcClient Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `connect()` | `RpcResponse<bool>` | Establish connection with heartbeat |
| `login(username, password)` | `RpcResponse<AuthResultData>` | Authenticate user |
| `logout()` | `RpcResponse<bool>` | Clear auth session |
| `getScores(since?)` | `RpcResponse<List<Score>>` | Fetch scores with optional delta |
| `upsertScore(score)` | `RpcResponse<ScoreSyncResult>` | Create/update score |
| `uploadPdf(id, bytes, name)` | `RpcResponse<FileUploadResult>` | Upload PDF file |

### SyncServiceV2 Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `startBackgroundSync()` | `Future<void>` | Start periodic sync |
| `stopBackgroundSync()` | `void` | Stop periodic sync |
| `syncNow()` | `Future<SyncResult>` | Trigger immediate sync |
| `queueChange(...)` | `Future<void>` | Queue operation for sync |
| `markModified(...)` | `Future<void>` | Mark entity as needing sync |
| `resolveConflict(...)` | `Future<void>` | Resolve sync conflict |
| `downloadPdf(id)` | `Future<String?>` | Download PDF on-demand |

### Error Codes Reference

| Code | Name | Retryable | Description |
|------|------|-----------|-------------|
| 1001 | networkUnavailable | Yes | No network connection |
| 1002 | connectionTimeout | Yes | Request timed out |
| 2001 | authenticationRequired | No | Need to login |
| 2002 | tokenExpired | Yes | Token needs refresh |
| 5001 | syncConflict | No | Data conflict detected |
| 5002 | versionMismatch | No | Version out of sync |

---

## File Structure

```
lib/
├── rpc/
│   ├── rpc_protocol.dart       # Protocol definitions
│   ├── rpc_interceptors.dart   # Interceptor chain
│   └── rpc_client.dart         # Type-safe client
├── sync/
│   ├── sync_state_machine.dart # State management
│   ├── operation_queue.dart    # Offline queue
│   ├── conflict_resolver.dart  # Conflict handling
│   └── sync_service_v2.dart    # Main sync service
└── rpc_sync.dart               # Barrel export

test/
├── rpc/
│   └── rpc_protocol_test.dart
└── sync/
    ├── sync_state_machine_test.dart
    ├── operation_queue_test.dart
    └── conflict_resolver_test.dart
```

---

## Summary

The refactored architecture provides:

1. **Unified Error Handling**: Structured error codes with retry classification
2. **Interceptor Chain**: Modular request/response processing
3. **Connection Management**: Heartbeat, reconnection, and state tracking
4. **State Machine**: Explicit sync states with clear transitions
5. **Offline Queue**: Persistent, prioritized operation queue
6. **Conflict Resolution**: Multiple strategies including CRDT support
7. **Idempotency**: Duplicate operations safely ignored
8. **Type Safety**: Strongly typed RPC calls and responses
9. **Testability**: All components have comprehensive unit tests
