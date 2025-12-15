# MuSheet Sync Implementation Plan

## Current State Analysis

### Local Architecture
- **Database**: Drift (SQLite) with tables: `scores`, `instrument_scores`, `annotations`, `setlists`, `setlist_scores`
- **Models**: Local models use `String` IDs (UUID), no sync metadata (version, syncStatus, updatedAt)
- **Providers**: `ScoresNotifier`, `SetlistsNotifier` read from local DB only
- **Storage**: PDFs stored locally at `pdfUrl` path

### Server Architecture
- **Database**: PostgreSQL via Serverpod ORM
- **Models**: Server models use `int` IDs (auto-increment), have sync metadata (version, syncStatus, updatedAt, deletedAt)
- **Endpoints**: `SyncEndpoint`, `ScoreEndpoint`, `SetlistEndpoint`, `FileEndpoint`
- **File Storage**: Server stores files in `uploads/` directory

### Gap Analysis

| Aspect | Local | Server | Gap |
|--------|-------|--------|-----|
| ID type | String (UUID) | int (auto-inc) | Need mapping table |
| Sync metadata | None | version, updatedAt, syncStatus | Need to add locally |
| Soft delete | Not supported | deletedAt field | Need to add locally |
| PDF storage | Local file path | Server file storage | Need upload/download |
| Conflict resolution | None | Version-based | Need to implement |

---

## Implementation Architecture

### Core Principles

1. **Offline-First**: All operations work locally first, sync in background
2. **Last-Write-Wins with Version**: Use version numbers for conflict detection
3. **Eventual Consistency**: Background sync ensures all devices converge
4. **Lazy File Sync**: PDFs download on-demand, not during metadata sync

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER ACTION                              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    LOCAL DATABASE (Drift)                        │
│  - Immediate write                                               │
│  - Update syncStatus = 'pending'                                 │
│  - Notify providers                                              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SYNC SERVICE (Background)                     │
│  - Monitor pending changes                                       │
│  - Push to server when online                                    │
│  - Pull from server periodically                                 │
│  - Handle conflicts                                              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SERVER (Serverpod)                            │
│  - Persist data                                                  │
│  - Return server version                                         │
│  - Store files                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Database Schema Changes

### New Local Tables

```sql
-- ID mapping between local UUID and server int ID
CREATE TABLE id_mappings (
  localId TEXT PRIMARY KEY,      -- UUID
  serverId INTEGER,              -- Server's auto-increment ID
  entityType TEXT NOT NULL,      -- 'score', 'instrumentScore', 'annotation', 'setlist'
  createdAt INTEGER NOT NULL
);

-- Sync metadata for each entity
CREATE TABLE sync_metadata (
  entityId TEXT PRIMARY KEY,     -- Local UUID
  entityType TEXT NOT NULL,
  version INTEGER DEFAULT 1,
  syncStatus TEXT DEFAULT 'pending',  -- 'pending', 'syncing', 'synced', 'conflict'
  lastSyncAt INTEGER,
  serverUpdatedAt INTEGER,
  deletedAt INTEGER,
  conflictData TEXT              -- JSON of server version when conflict
);

-- Global sync state
CREATE TABLE sync_state (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
-- Keys: 'lastFullSyncAt', 'lastIncrementalSyncAt', 'syncInProgress'
```

### Model Updates

Add sync fields to existing Drift tables:

```dart
// In scores table
IntColumn get version => integer().withDefault(const Constant(1))();
TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
IntColumn get serverUpdatedAt => integer().nullable()();
IntColumn get deletedAt => integer().nullable()();

// In instrument_scores table
IntColumn get version => integer().withDefault(const Constant(1))();
TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
TextColumn get pdfSyncStatus => text().withDefault(const Constant('pending'))();  // For file sync
TextColumn get pdfHash => text().nullable()();  // To detect file changes

// In annotations table
IntColumn get version => integer().withDefault(const Constant(1))();
TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

// In setlists table
IntColumn get version => integer().withDefault(const Constant(1))();
TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
IntColumn get deletedAt => integer().nullable()();
```

---

## Sync Service Architecture

### SyncService Class

```dart
class SyncService {
  // Singleton
  static SyncService? _instance;

  // Dependencies
  final DatabaseService _db;
  final BackendService _backend;

  // State
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;

  // Configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration retryDelay = Duration(seconds: 30);

  // Public API
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  Future<void> startBackgroundSync();
  Future<void> stopBackgroundSync();
  Future<SyncResult> syncNow();
  Future<void> syncScore(String scoreId);
  Future<void> syncSetlist(String setlistId);
  Future<void> downloadPdf(String instrumentScoreId);
}
```

### Sync Status

```dart
enum SyncState {
  idle,
  syncing,
  error,
  offline,
}

class SyncStatus {
  final SyncState state;
  final int pendingChanges;
  final int totalItems;
  final int syncedItems;
  final String? errorMessage;
  final DateTime? lastSyncAt;
}

class SyncResult {
  final bool success;
  final int uploadedCount;
  final int downloadedCount;
  final int conflictCount;
  final List<SyncConflict> conflicts;
  final String? errorMessage;
}
```

---

## Sync Algorithms

### 1. Full Sync (Initial/Login)

```
1. Set syncState = 'syncing'
2. Get lastFullSyncAt from sync_state table

3. PULL PHASE:
   a. Call server.sync.syncAll(userId, lastSyncAt: null)
   b. For each server score:
      - Check if localId exists in id_mappings by serverId
      - If not: create new local entity with UUID, add to id_mappings
      - If exists: compare versions
        - server.version > local.version → update local
        - server.version <= local.version → skip (local is newer or same)
   c. Repeat for instrumentScores, annotations, setlists

4. PUSH PHASE:
   a. Get all local entities where syncStatus = 'pending'
   b. For each pending entity:
      - Get serverId from id_mappings (null if new)
      - Call server.score.upsertScore()
      - Handle response:
        - success: update syncStatus = 'synced', store serverId in id_mappings
        - conflict: mark syncStatus = 'conflict', store conflictData

5. Update lastFullSyncAt = now()
6. Set syncState = 'idle'
```

### 2. Incremental Sync (Background)

```
1. Check if online (BackendService.status == connected)
2. If offline: return

3. PUSH pending changes:
   a. Get entities where syncStatus = 'pending', order by updatedAt ASC
   b. For each (limit 10 per batch):
      - Push to server
      - Update syncStatus based on result
   c. If any failures: schedule retry

4. PULL new changes:
   a. Call server.sync.getSyncStatus(userId)
   b. If server.lastUpdated > local.lastIncrementalSyncAt:
      - Call server.sync.syncAll(userId, lastSyncAt: lastIncrementalSyncAt)
      - Merge changes (same as full sync pull)
   c. Update lastIncrementalSyncAt = now()
```

### 3. Conflict Resolution

```dart
enum ConflictResolution {
  keepLocal,    // Overwrite server with local
  keepServer,   // Overwrite local with server
  keepBoth,     // Create duplicate (for scores)
  manual,       // Show UI to user
}

class SyncConflict {
  final String entityId;
  final String entityType;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final DateTime localUpdatedAt;
  final DateTime serverUpdatedAt;
}

// Default resolution strategy:
// - For scores/setlists: Last-write-wins based on updatedAt
// - For annotations: Keep both (merge points)
// - For PDF files: Keep server version (it's the source of truth)
```

### 4. File Sync (PDFs)

```
PDF Upload:
1. When user imports PDF:
   - Store locally at instrumentScore.pdfUrl
   - Set pdfSyncStatus = 'pending'
   - Compute pdfHash
2. Background sync detects pdfSyncStatus = 'pending':
   - Read file from local path
   - Call server.file.uploadPdf(instrumentScoreId, fileData)
   - On success: set pdfSyncStatus = 'synced'

PDF Download:
1. When opening score viewer:
   - Check if local PDF exists at pdfUrl
   - If exists: use local file
   - If not: check if pdfSyncStatus = 'synced' (means server has it)
     - Show loading state
     - Call server.file.downloadPdf(instrumentScoreId)
     - Save to local path
     - Update UI
2. Background pre-fetch (optional):
   - Download PDFs for recently accessed scores
   - Download PDFs when on WiFi
```

---

## Provider Integration

### SyncAwareScoresNotifier

```dart
class ScoresNotifier extends Notifier<List<Score>> {
  @override
  List<Score> build() {
    _loadFromDatabase();
    _setupSyncListener();
    return [];
  }

  void _setupSyncListener() {
    // Listen to sync service for updates
    ref.listen(syncServiceProvider, (previous, next) {
      if (next.state == SyncState.idle && previous?.state == SyncState.syncing) {
        // Sync completed, reload from database
        _loadFromDatabase();
      }
    });
  }

  Future<void> addScore(Score score) async {
    // 1. Save to local database with syncStatus = 'pending'
    await _db.insertScore(score.copyWith(syncStatus: 'pending'));

    // 2. Update state immediately (optimistic update)
    state = [...state, score];

    // 3. Trigger background sync
    ref.read(syncServiceProvider).syncScore(score.id);
  }

  Future<void> updateScore(Score score) async {
    // 1. Increment version, set syncStatus = 'pending'
    final updated = score.copyWith(
      version: score.version + 1,
      syncStatus: 'pending',
    );

    // 2. Save locally
    await _db.updateScore(updated);

    // 3. Update state
    state = state.map((s) => s.id == score.id ? updated : s).toList();

    // 4. Trigger sync
    ref.read(syncServiceProvider).syncScore(score.id);
  }

  Future<void> deleteScore(String id) async {
    // Soft delete: set deletedAt, syncStatus = 'pending'
    await _db.softDeleteScore(id);

    // Remove from state
    state = state.where((s) => s.id != id).toList();

    // Sync deletion to server
    ref.read(syncServiceProvider).syncScore(id);
  }
}
```

### Score Viewer Integration

```dart
class ScoreViewerScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfStatus = ref.watch(pdfStatusProvider(instrumentScore.id));

    return switch (pdfStatus) {
      PdfStatus.available => PdfViewer(path: instrumentScore.pdfUrl),
      PdfStatus.downloading => LoadingIndicator(message: 'Downloading PDF...'),
      PdfStatus.notAvailable => ErrorState(
        message: 'PDF not available offline',
        action: 'Download',
        onAction: () => ref.read(syncServiceProvider).downloadPdf(instrumentScore.id),
      ),
    };
  }
}

// Listen for PDF updates
ref.listen(pdfUpdateProvider(instrumentScore.id), (prev, next) {
  if (next != null && next.path != instrumentScore.pdfUrl) {
    // PDF was updated, show refresh option or auto-reload
    showSnackBar('PDF updated. Tap to refresh.');
  }
});
```

---

## Implementation Order

### Phase 1: Database Schema (Day 1)

1. Add new columns to Drift tables:
   - `version`, `syncStatus`, `deletedAt` to scores, setlists
   - `pdfSyncStatus`, `pdfHash` to instrument_scores
2. Create `id_mappings` table
3. Create `sync_metadata` table
4. Create `sync_state` table
5. Run migration

### Phase 2: Sync Service Core (Day 2-3)

1. Create `SyncService` class with:
   - ID mapping helpers
   - Push single entity methods
   - Pull and merge methods
   - Conflict detection
2. Create `SyncStatus` model and stream
3. Add background timer
4. Add connectivity check

### Phase 3: Provider Integration (Day 4)

1. Update `ScoresNotifier`:
   - Add syncStatus handling
   - Listen to sync updates
   - Trigger sync on changes
2. Update `SetlistsNotifier` similarly
3. Add `syncServiceProvider`

### Phase 4: File Sync (Day 5)

1. Implement PDF upload in SyncService
2. Implement PDF download on-demand
3. Add `pdfStatusProvider` for UI
4. Handle offline PDF access

### Phase 5: UI Integration (Day 6)

1. Add sync status indicator in app
2. Add pull-to-refresh for manual sync
3. Add conflict resolution UI
4. Add offline mode indicator

### Phase 6: Testing & Edge Cases (Day 7)

1. Test multi-device sync
2. Test conflict scenarios
3. Test offline mode
4. Test large file uploads
5. Test network interruption

---

## API Usage Summary

### Server Endpoints Used

```dart
// Status check
client.status.health()
client.status.info()

// Authentication
client.auth.login(username, password)
client.auth.register(username, password)
client.auth.validateToken(token)

// Sync
client.sync.syncAll(userId, lastSyncAt: timestamp)
client.sync.pushChanges(userId, scores, instrumentScores, ...)
client.sync.getSyncStatus(userId)

// Scores
client.score.getScores(userId, since: timestamp)
client.score.upsertScore(userId, score)
client.score.deleteScore(userId, scoreId)
client.score.getInstrumentScores(userId, scoreId)

// Files
client.file.uploadPdf(userId, instrumentScoreId, fileData, fileName)
client.file.downloadPdf(userId, instrumentScoreId)

// Setlists
client.setlist.getSetlists(userId)
client.setlist.createSetlist(userId, name, description)
client.setlist.updateSetlist(userId, setlistId, ...)
client.setlist.deleteSetlist(userId, setlistId)
```

---

## Configuration

```dart
class SyncConfig {
  // Sync intervals
  static const fullSyncInterval = Duration(hours: 24);
  static const incrementalSyncInterval = Duration(minutes: 5);
  static const retryDelay = Duration(seconds: 30);
  static const maxRetries = 3;

  // Batch sizes
  static const pushBatchSize = 10;
  static const pullBatchSize = 50;

  // File sync
  static const maxFileSize = 50 * 1024 * 1024; // 50MB
  static const autoDownloadOnWifi = true;
  static const preloadRecentScores = 5;

  // Conflict resolution
  static const defaultResolution = ConflictResolution.lastWriteWins;
  static const showConflictDialogFor = ['score', 'setlist'];
}
```

---

## Error Handling

```dart
enum SyncError {
  networkUnavailable,
  serverUnreachable,
  authenticationFailed,
  quotaExceeded,
  fileTooLarge,
  conflictUnresolved,
  unknownError,
}

class SyncException implements Exception {
  final SyncError error;
  final String message;
  final dynamic originalError;

  bool get isRetryable => [
    SyncError.networkUnavailable,
    SyncError.serverUnreachable,
  ].contains(error);
}
```

---

## Monitoring & Debugging

```dart
// Enable debug logging
SyncService.enableDebugLogging = true;

// Sync events log
class SyncLogger {
  static void log(String event, Map<String, dynamic> data);
  static void logError(String event, dynamic error, StackTrace stack);
  static List<SyncLogEntry> getRecentLogs(int count);
}

// Debug screen (in settings)
class SyncDebugScreen {
  // Shows: last sync time, pending changes count, sync history, errors
}
```
