import 'package:drift/drift.dart';
import 'team_scores_table.dart';

/// TeamInstrumentScore table - independent from personal InstrumentScore
/// Per TEAM_SYNC_LOGIC.md: Team data uses copy mode with PDF hash reuse
@DataClassName('TeamInstrumentScoreEntity')
class TeamInstrumentScores extends Table {
  TextColumn get id => text()();
  TextColumn get teamScoreId => text().references(TeamScores, #id, onDelete: KeyAction.cascade)();
  TextColumn get instrumentType => text()();
  TextColumn get customInstrument => text().nullable()();
  TextColumn get pdfPath => text().nullable()();
  TextColumn get thumbnail => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  // PDF sync - reuses global pdfHash mechanism
  TextColumn get pdfHash => text().nullable()();
  TextColumn get pdfSyncStatus => text().withDefault(const Constant('pending'))();

  // Shared annotations (all team members share the same annotations)
  TextColumn get annotationsJson => text().withDefault(const Constant('[]'))();

  // Source tracking
  IntColumn get sourceInstrumentScoreId => integer().nullable()();

  // Sync fields
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get serverId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
