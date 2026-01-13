import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/scores_table.dart';
import 'tables/instrument_scores_table.dart';
import 'tables/annotations_table.dart';
import 'tables/setlists_table.dart';
import 'tables/setlist_scores_table.dart';
import 'tables/app_state_table.dart';
import 'tables/sync_state_table.dart';
// Team tables (metadata only - scores/setlists use unified tables with scopeType)
import 'tables/teams_table.dart';
import 'tables/team_members_table.dart';
import 'tables/team_sync_state_table.dart';

part 'database.g.dart';

/// Unified database schema per sync_logic.md
/// Uses scopeType/scopeId to distinguish user vs team data in same tables
@DriftDatabase(tables: [
  // Unified library tables (scopeType: 'user' or 'team')
  Scores,
  InstrumentScores,
  Annotations,
  Setlists,
  SetlistScores,
  AppState,
  SyncState,
  // Team metadata tables
  Teams,
  TeamMembers,
  TeamSyncState,
])
class AppDatabase extends _$AppDatabase {
  // Singleton instance
  static AppDatabase? _instance;

  // Factory constructor for singleton
  factory AppDatabase() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  // Private constructor
  AppDatabase._internal() : super(_openConnection());

  // Constructor for testing with custom executor (e.g., in-memory database)
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4; // Unified tables with scopeType/scopeId

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 4) {
            // Version 4: Unified tables with scopeType/scopeId
            // For simplicity, recreate all tables (data migration not handled)
            // In production, you would migrate data properly
            await m.createAll();
          }
        },
        beforeOpen: (details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ============================================================================
  // DATA MANAGEMENT METHODS
  // ============================================================================

  /// Clear all user data from database (for logout)
  /// Per APP_SYNC_LOGIC.md §1.5.3: On logout, delete all database table contents
  Future<void> clearAllUserData() async {
    // Delete in reverse dependency order to avoid foreign key issues
    await delete(annotations).go();
    await delete(setlistScores).go();
    await delete(instrumentScores).go();
    await delete(scores).go();
    await delete(setlists).go();
    await delete(syncState).go();
    // Team metadata
    await delete(teamMembers).go();
    await delete(teams).go();
    await delete(teamSyncState).go();
    // Note: appState is kept for app preferences
  }

  /// Get count of pending (unsynced) changes for user scope
  Future<int> getPendingChangesCount() async {
    var count = 0;

    // Get all user-scoped scores first (to filter related tables)
    final userScores = await (select(scores)
      ..where((s) => s.scopeType.equals('user'))).get();
    final userScoreIds = userScores.map((s) => s.id).toSet();

    final pendingScores = await (select(scores)
      ..where((s) => s.scopeType.equals('user') & s.syncStatus.equals('pending'))).get();
    count += pendingScores.length;

    // Filter instrument scores by user scope scores
    if (userScoreIds.isNotEmpty) {
      final pendingInstrumentScores = await (select(instrumentScores)
        ..where((is_) => is_.scoreId.isIn(userScoreIds) & is_.syncStatus.equals('pending'))).get();
      count += pendingInstrumentScores.length;
    }

    // Get all user-scoped setlists first (to filter setlistScores)
    final userSetlists = await (select(setlists)
      ..where((s) => s.scopeType.equals('user'))).get();
    final userSetlistIds = userSetlists.map((s) => s.id).toSet();

    final pendingSetlists = await (select(setlists)
      ..where((s) => s.scopeType.equals('user') & s.syncStatus.equals('pending'))).get();
    count += pendingSetlists.length;

    // Filter setlist scores by user scope setlists
    if (userSetlistIds.isNotEmpty) {
      final pendingSetlistScores = await (select(setlistScores)
        ..where((ss) => ss.setlistId.isIn(userSetlistIds) & ss.syncStatus.equals('pending'))).get();
      count += pendingSetlistScores.length;
    }

    return count;
  }

  /// Get count of pending Team changes for a specific team
  Future<int> getTeamPendingChangesCount(int teamId) async {
    var count = 0;

    final pendingTeamScores = await (select(scores)
      ..where((s) => s.scopeType.equals('team') & s.scopeId.equals(teamId) & s.syncStatus.equals('pending'))).get();
    count += pendingTeamScores.length;

    // Get instrument scores for these team scores
    final teamScoreIds = pendingTeamScores.map((s) => s.id).toSet();
    if (teamScoreIds.isNotEmpty) {
      final pendingTeamInstrumentScores = await (select(instrumentScores)
        ..where((is_) => is_.scoreId.isIn(teamScoreIds) & is_.syncStatus.equals('pending'))).get();
      count += pendingTeamInstrumentScores.length;
    }

    final pendingTeamSetlists = await (select(setlists)
      ..where((s) => s.scopeType.equals('team') & s.scopeId.equals(teamId) & s.syncStatus.equals('pending'))).get();
    count += pendingTeamSetlists.length;

    final teamSetlistIds = pendingTeamSetlists.map((s) => s.id).toSet();
    if (teamSetlistIds.isNotEmpty) {
      final pendingTeamSetlistScores = await (select(setlistScores)
        ..where((ss) => ss.setlistId.isIn(teamSetlistIds) & ss.syncStatus.equals('pending'))).get();
      count += pendingTeamSetlistScores.length;
    }

    return count;
  }

  /// Delete all local PDF files
  Future<void> deleteAllLocalPdfFiles() async {
    final allInstrumentScores = await select(instrumentScores).get();
    for (final is_ in allInstrumentScores) {
      if (is_.pdfPath != null && is_.pdfPath!.isNotEmpty) {
        try {
          final file = File(is_.pdfPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {
          // Ignore file deletion errors
        }
      }
    }
  }

  /// Clear all data for a specific team (when leaving team)
  Future<void> clearTeamData(int teamServerId) async {
    // Get team scores
    final teamScoreList = await (select(scores)
      ..where((s) => s.scopeType.equals('team') & s.scopeId.equals(teamServerId))).get();

    // Delete instrument scores for team scores
    for (final ts in teamScoreList) {
      await (delete(instrumentScores)
        ..where((is_) => is_.scoreId.equals(ts.id))).go();
    }

    // Get team setlists
    final teamSetlistList = await (select(setlists)
      ..where((s) => s.scopeType.equals('team') & s.scopeId.equals(teamServerId))).get();

    // Delete setlist scores for team setlists
    for (final tsl in teamSetlistList) {
      await (delete(setlistScores)
        ..where((ss) => ss.setlistId.equals(tsl.id))).go();
    }

    // Delete team scores
    await (delete(scores)
      ..where((s) => s.scopeType.equals('team') & s.scopeId.equals(teamServerId))).go();

    // Delete team setlists
    await (delete(setlists)
      ..where((s) => s.scopeType.equals('team') & s.scopeId.equals(teamServerId))).go();

    // Delete team members
    final teamRecords = await (select(teams)
      ..where((t) => t.serverId.equals(teamServerId))).get();
    if (teamRecords.isNotEmpty) {
      final teamLocalId = teamRecords.first.id;
      await (delete(teamMembers)
        ..where((tm) => tm.teamId.equals(teamLocalId))).go();
      await (delete(teams)
        ..where((t) => t.id.equals(teamLocalId))).go();
    }

    // Delete team sync state
    await (delete(teamSyncState)
      ..where((tss) => tss.teamId.equals(teamServerId))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'musheet.db'));
    return NativeDatabase(file);
  });
}
