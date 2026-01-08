import 'package:drift/drift.dart';
import 'setlists_table.dart';
import 'scores_table.dart';

/// Unified SetlistScore table for both user and team scopes
/// Inherits scope from parent Setlist via foreign key
@DataClassName('SetlistScoreEntity')
class SetlistScores extends Table {
  TextColumn get id => text()(); // Local ID for sync tracking
  TextColumn get setlistId => text().references(Setlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get scoreId => text().references(Scores, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderIndex => integer()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  // Sync fields (aligned with sync_logic.md)
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get serverId => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Soft delete support

  @override
  Set<Column> get primaryKey => {id};
}