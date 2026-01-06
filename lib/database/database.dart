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
// Team tables
import 'tables/teams_table.dart';
import 'tables/team_members_table.dart';
import 'tables/team_scores_table.dart';
import 'tables/team_instrument_scores_table.dart';
import 'tables/team_setlists_table.dart';
import 'tables/team_setlist_scores_table.dart';
import 'tables/team_sync_state_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  // Personal library tables
  Scores,
  InstrumentScores,
  Annotations,
  Setlists,
  SetlistScores,
  AppState,
  SyncState,
  // Team tables
  Teams,
  TeamMembers,
  TeamScores,
  TeamInstrumentScores,
  TeamSetlists,
  TeamSetlistScores,
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

  @override
  int get schemaVersion => 3; // Added avatarUrl to team_members

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Add Team tables in version 2
            await m.createTable(teams);
            await m.createTable(teamMembers);
            await m.createTable(teamScores);
            await m.createTable(teamInstrumentScores);
            await m.createTable(teamSetlists);
            await m.createTable(teamSetlistScores);
            await m.createTable(teamSyncState);
          }
          if (from < 3) {
            // Add avatarUrl column to team_members in version 3
            await m.addColumn(teamMembers, teamMembers.avatarUrl);
          }
        },
      );

  // ============================================================================
  // DATA MANAGEMENT METHODS
  // ============================================================================

  /// Clear all user data from database (for logout)
  /// Per APP_SYNC_LOGIC.md §1.5.3: On logout, delete all database table contents
  Future<void> clearAllUserData() async {
    // Delete in reverse dependency order to avoid foreign key issues
    // Personal library
    await delete(annotations).go();
    await delete(setlistScores).go();
    await delete(instrumentScores).go();
    await delete(scores).go();
    await delete(setlists).go();
    await delete(syncState).go();
    // Team data
    await delete(teamSetlistScores).go();
    await delete(teamInstrumentScores).go();
    await delete(teamScores).go();
    await delete(teamSetlists).go();
    await delete(teamMembers).go();
    await delete(teams).go();
    await delete(teamSyncState).go();
    // Note: appState is kept for app preferences
  }

  /// Get count of pending (unsynced) changes
  /// Used to warn user before logout
  Future<int> getPendingChangesCount() async {
    var count = 0;

    final pendingScores = await (select(scores)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    count += pendingScores.length;

    final pendingInstrumentScores = await (select(instrumentScores)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    count += pendingInstrumentScores.length;

    // Note: Annotations don't have syncStatus field - they are embedded in InstrumentScore
    // A pending InstrumentScore already indicates pending annotation changes

    final pendingSetlists = await (select(setlists)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    count += pendingSetlists.length;

    final pendingSetlistScores = await (select(setlistScores)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    count += pendingSetlistScores.length;

    return count;
  }

  /// Get count of pending Team changes
  Future<int> getTeamPendingChangesCount() async {
    var count = 0;

    final pendingTeamScores = await (select(teamScores)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    count += pendingTeamScores.length;

    final pendingTeamInstrumentScores = await (select(teamInstrumentScores)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    count += pendingTeamInstrumentScores.length;

    final pendingTeamSetlists = await (select(teamSetlists)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    count += pendingTeamSetlists.length;

    final pendingTeamSetlistScores = await (select(teamSetlistScores)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    count += pendingTeamSetlistScores.length;

    return count;
  }

  /// Delete all local PDF files
  /// Per APP_SYNC_LOGIC.md §1.5.3: On logout, delete all local PDF files
  Future<void> deleteAllLocalPdfFiles() async {
    // Personal library PDFs
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

    // Team PDFs (shared storage - only delete if no other reference)
    // Note: Team PDFs use the same /pdfs/{hash}.pdf storage as personal library
    // The actual cleanup is handled by reference counting in sync service
  }

  /// Clear all data for a specific team (when leaving team)
  Future<void> clearTeamData(int teamServerId) async {
    // Get local team ID
    final teamRecords = await (select(teams)
      ..where((t) => t.serverId.equals(teamServerId))).get();
    if (teamRecords.isEmpty) return;

    final teamLocalId = teamRecords.first.id;

    // Delete in reverse dependency order
    // Get all TeamScores for this team first
    final teamScoreRecords = await (select(teamScores)
      ..where((ts) => ts.teamId.equals(teamServerId))).get();

    for (final ts in teamScoreRecords) {
      // Delete TeamInstrumentScores
      await (delete(teamInstrumentScores)
        ..where((tis) => tis.teamScoreId.equals(ts.id))).go();
    }

    // Get all TeamSetlists for this team
    final teamSetlistRecords = await (select(teamSetlists)
      ..where((tsl) => tsl.teamId.equals(teamServerId))).get();

    for (final tsl in teamSetlistRecords) {
      // Delete TeamSetlistScores
      await (delete(teamSetlistScores)
        ..where((tss) => tss.teamSetlistId.equals(tsl.id))).go();
    }

    // Delete TeamScores
    await (delete(teamScores)
      ..where((ts) => ts.teamId.equals(teamServerId))).go();

    // Delete TeamSetlists
    await (delete(teamSetlists)
      ..where((tsl) => tsl.teamId.equals(teamServerId))).go();

    // Delete TeamMembers
    await (delete(teamMembers)
      ..where((tm) => tm.teamId.equals(teamLocalId))).go();

    // Delete Team
    await (delete(teams)
      ..where((t) => t.id.equals(teamLocalId))).go();

    // Delete TeamSyncState
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
