import 'package:drift/drift.dart';
import 'scores_table.dart';

@DataClassName('InstrumentScoreEntity')
class InstrumentScores extends Table {
  TextColumn get id => text()();
  TextColumn get scoreId => text().references(Scores, #id, onDelete: KeyAction.cascade)();
  TextColumn get instrumentType => text()();
  TextColumn get customInstrument => text().nullable()();
  TextColumn get pdfPath => text()();
  TextColumn get thumbnail => text().nullable()();
  DateTimeColumn get dateAdded => dateTime()();

  // Sync fields
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get serverId => integer().nullable()();
  TextColumn get pdfSyncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get pdfHash => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
