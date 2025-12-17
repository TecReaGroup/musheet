import 'package:drift/drift.dart';
import 'setlists_table.dart';
import 'scores_table.dart';

@DataClassName('SetlistScoreEntity')
class SetlistScores extends Table {
  TextColumn get setlistId => text().references(Setlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get scoreId => text().references(Scores, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderIndex => integer()();

  // Sync fields (aligned with sync_logic.md)
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get serverId => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Soft delete support

  @override
  Set<Column> get primaryKey => {setlistId, scoreId};
}