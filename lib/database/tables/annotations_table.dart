import 'package:drift/drift.dart';
import 'instrument_scores_table.dart';

@DataClassName('AnnotationEntity')
class Annotations extends Table {
  TextColumn get id => text()();
  TextColumn get instrumentScoreId => text().references(InstrumentScores, #id, onDelete: KeyAction.cascade)();
  TextColumn get annotationType => text()();
  TextColumn get color => text()();
  RealColumn get strokeWidth => real()();
  TextColumn get points => text().nullable()(); // JSON-encoded list of doubles
  TextColumn get textContent => text().nullable()();
  RealColumn get posX => real().nullable()();
  RealColumn get posY => real().nullable()();
  IntColumn get pageNumber => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}