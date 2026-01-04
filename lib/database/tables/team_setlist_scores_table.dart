import 'package:drift/drift.dart';
import 'team_setlists_table.dart';
import 'team_scores_table.dart';

/// TeamSetlistScore table - links TeamSetlist to TeamScore
/// Per TEAM_SYNC_LOGIC.md: References TeamScore, not personal Score
@DataClassName('TeamSetlistScoreEntity')
class TeamSetlistScores extends Table {
  TextColumn get id => text()();
  TextColumn get teamSetlistId => text().references(TeamSetlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get teamScoreId => text().references(TeamScores, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

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
