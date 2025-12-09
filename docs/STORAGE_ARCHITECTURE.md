# Hybrid Storage Architecture Design

## Overview
This document outlines the persistent storage architecture for MuSheet, implementing a three-tier hybrid strategy using **Drift** for structured metadata, **shared_preferences** for lightweight settings, and **path_provider** for binary PDF files.

## Storage Strategy

### 1. **Drift Database** (SQLite)
**Purpose**: Store structured metadata for scores, setlists, and app state

**Tables**:
- `scores`: Core score metadata (id, title, composer, bpm, dateAdded)
- `instrument_scores`: Instrument-specific scores with PDF references (id, scoreId, instrumentType, customInstrument, pdfPath, thumbnail, dateAdded)
- `annotations`: Drawing/text annotations (id, instrumentScoreId, type, color, width, points, text, x, y, page)
- `setlists`: Setlist metadata (id, name, description, dateCreated)
- `setlist_scores`: Junction table for setlist-score relationships (setlistId, scoreId, orderIndex)
- `app_state`: Key-value pairs for app state (key, value)

**Key Features**:
- Foreign key relationships
- Indexes for fast queries
- Type-safe queries with generated code
- Migration support

### 2. **SharedPreferences**
**Purpose**: Store simple key-value settings

**Data Stored**:
- `theme_mode`: 'light' | 'dark' | 'system'
- `user_name`: String (optional)
- `auth_token`: String (optional, for future cloud sync)
- `default_instrument`: String
- `onboarding_completed`: bool
- `metronome_sound_enabled`: bool

### 3. **File System** (path_provider)
**Purpose**: Store actual PDF files and thumbnails

**Directory Structure**:
```
{AppDocumentsDirectory}/
├── pdfs/
│   ├── {scoreId}/
│   │   ├── {instrumentScoreId}.pdf
│   │   └── {instrumentScoreId}_thumb.jpg
│   └── ...
└── cache/
    └── temp_pdfs/
```

**File Naming Convention**:
- PDF: `{instrumentScoreId}.pdf`
- Thumbnail: `{instrumentScoreId}_thumb.jpg`
- Path stored in Drift: Relative path from app documents

## Architecture Layers

### Layer 1: Database Layer (`lib/database/`)
- `database.dart`: Drift database definition
- `tables/`: Table definitions
  - `scores_table.dart`
  - `instrument_scores_table.dart`
  - `annotations_table.dart`
  - `setlists_table.dart`
  - `setlist_scores_table.dart`
  - `app_state_table.dart`

### Layer 2: Service Layer (`lib/services/`)
- `database_service.dart`: Drift database operations
- `preferences_service.dart`: SharedPreferences wrapper
- `file_storage_service.dart`: PDF file operations
- `storage_service.dart`: Unified storage facade

### Layer 3: Repository Layer (`lib/repositories/`)
- `scores_repository.dart`: Score CRUD operations
- `setlists_repository.dart`: Setlist CRUD operations
- `app_state_repository.dart`: App state management

### Layer 4: Provider Layer (`lib/providers/`)
- Update existing providers to use repositories
- Add new state providers:
  - `lastOpenedScoreProvider`
  - `lastOpenedInstrumentProvider`
  - `themeProvider`
  - `userSettingsProvider`

## Data Flow

### Adding a Score
1. User selects PDF file → File picker
2. Service copies PDF to app documents → `file_storage_service.dart`
3. Generate thumbnail → `file_storage_service.dart`
4. Insert metadata to Drift → `database_service.dart`
5. Update Riverpod state → `scores_provider.dart`

### Loading Scores on App Start
1. Initialize database → `database_service.dart`
2. Query all scores → `scores_repository.dart`
3. Load into Riverpod → `scores_provider.dart`
4. Restore app state → `app_state_repository.dart`

### Deleting a Score
1. Remove from Riverpod state → `scores_provider.dart`
2. Delete from database → `database_service.dart`
3. Delete PDF files → `file_storage_service.dart`

## Implementation Plan

### Phase 1: Database Setup
1. ✅ Add drift dependencies to pubspec.yaml
2. ✅ Create table definitions
3. ✅ Generate database code
4. ✅ Create database service

### Phase 2: Service Layer
1. ✅ Implement preferences service
2. ✅ Implement file storage service
3. ✅ Create unified storage service

### Phase 3: Repository Layer
1. ✅ Create scores repository
2. ✅ Create setlists repository
3. ✅ Create app state repository

### Phase 4: Provider Migration
1. ✅ Update scores provider to use repository
2. ✅ Update setlists provider to use repository
3. ✅ Add state persistence providers

### Phase 5: Initialization
1. ✅ Initialize services in main.dart
2. ✅ Load persisted data on app start
3. ✅ Test data persistence

## Key Considerations

### Performance
- Use indexes on frequently queried columns (title, composer, dateAdded)
- Lazy load annotations (only when viewing score)
- Cache file paths in memory

### Data Integrity
- Foreign key constraints ensure referential integrity
- Transactions for multi-table operations
- Cascade deletes for score → instrument_scores → annotations

### Migration Strategy
- Current in-memory data will be migrated on first run
- Use Drift's migration system for schema changes
- Backup database before migrations

### Error Handling
- Graceful degradation if database fails
- File system error handling (disk full, permissions)
- Data validation before persistence

## Benefits

1. **Persistence**: Data survives app restarts
2. **Performance**: Fast queries with indexes
3. **Type Safety**: Drift generates type-safe code
4. **Scalability**: Can handle thousands of scores
5. **Offline First**: No network dependency
6. **Future-Ready**: Easy to add cloud sync later

## Next Steps

1. Implement database schema
2. Create service layer
3. Migrate existing providers
4. Add comprehensive tests
5. Document API usage