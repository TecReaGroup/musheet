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

  @override
  Set<Column> get primaryKey => {id};
}