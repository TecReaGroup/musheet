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

part 'database.g.dart';

@DriftDatabase(tables: [
  Scores,
  InstrumentScores,
  Annotations,
  Setlists,
  SetlistScores,
  AppState,
  SyncState,
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
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

  /// Delete all local PDF files
  /// Per APP_SYNC_LOGIC.md §1.5.3: On logout, delete all local PDF files
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'musheet.db'));
    return NativeDatabase(file);
  });
}
