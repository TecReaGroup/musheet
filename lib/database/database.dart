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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Add sync fields to scores
            await m.addColumn(scores, scores.version);
            await m.addColumn(scores, scores.syncStatus);
            await m.addColumn(scores, scores.serverId);
            await m.addColumn(scores, scores.updatedAt);
            await m.addColumn(scores, scores.deletedAt);

            // Add sync fields to instrument_scores
            await m.addColumn(instrumentScores, instrumentScores.version);
            await m.addColumn(instrumentScores, instrumentScores.syncStatus);
            await m.addColumn(instrumentScores, instrumentScores.serverId);
            await m.addColumn(instrumentScores, instrumentScores.pdfSyncStatus);
            await m.addColumn(instrumentScores, instrumentScores.pdfHash);
            await m.addColumn(instrumentScores, instrumentScores.updatedAt);

            // Add sync fields to setlists
            await m.addColumn(setlists, setlists.version);
            await m.addColumn(setlists, setlists.syncStatus);
            await m.addColumn(setlists, setlists.serverId);
            await m.addColumn(setlists, setlists.updatedAt);
            await m.addColumn(setlists, setlists.deletedAt);

            // Create sync_state table
            await m.createTable(syncState);

            // Set default values for existing records
            await customStatement("UPDATE scores SET version = 1, sync_status = 'pending' WHERE version IS NULL OR sync_status IS NULL");
            await customStatement("UPDATE instrument_scores SET version = 1, sync_status = 'pending', pdf_sync_status = 'pending' WHERE version IS NULL OR sync_status IS NULL");
            await customStatement("UPDATE setlists SET version = 1, sync_status = 'pending' WHERE version IS NULL OR sync_status IS NULL");
          }
        },
        beforeOpen: (details) async {
          // Fix NULL sync fields for existing records (handles case where migration already ran)
          await customStatement("UPDATE scores SET version = 1 WHERE version IS NULL");
          await customStatement("UPDATE scores SET sync_status = 'pending' WHERE sync_status IS NULL");
          await customStatement("UPDATE instrument_scores SET version = 1 WHERE version IS NULL");
          await customStatement("UPDATE instrument_scores SET sync_status = 'pending' WHERE sync_status IS NULL");
          await customStatement("UPDATE instrument_scores SET pdf_sync_status = 'pending' WHERE pdf_sync_status IS NULL");
          await customStatement("UPDATE setlists SET version = 1 WHERE version IS NULL");
          await customStatement("UPDATE setlists SET sync_status = 'pending' WHERE sync_status IS NULL");
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'musheet.db'));
    return NativeDatabase(file);
  });
}
