import 'package:drift/drift.dart';
import 'scores_table.dart';

/// Unified InstrumentScore table for both user and team scopes
/// Inherits scope from parent Score via foreign key
@DataClassName('InstrumentScoreEntity')
class InstrumentScores extends Table {
  TextColumn get id => text()();
  TextColumn get scoreId => text().references(Scores, #id, onDelete: KeyAction.cascade)();
  TextColumn get instrumentType => text()();
  TextColumn get customInstrument => text().nullable()();
  TextColumn get pdfPath => text().nullable()();
  TextColumn get thumbnail => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  // Order index for sorting instrument scores within a score
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  // Team-specific fields (nullable for user scope)
  IntColumn get sourceInstrumentScoreId => integer().nullable()(); // Original IS if copied

  // Sync fields (aligned with sync_logic.md)
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get serverId => integer().nullable()();
  TextColumn get pdfSyncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get pdfHash => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Soft delete support

  // Per sync_logic.md §2.6: Annotations are embedded in InstrumentScore as JSON
  // This field stores all annotations for this instrument score
  // Format: [{"id": "uuid", "pageNumber": 1, "type": "draw", "color": "#FF0000", ...}, ...]
  TextColumn get annotationsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}
