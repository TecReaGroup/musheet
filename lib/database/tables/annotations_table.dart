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

  // Sync fields (aligned with sync_logic.md)
  // Note: Annotations use physical delete, not soft delete (no deletedAt field)
  // Note: userId is NOT stored on frontend - backend extracts it from session
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get serverId => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}