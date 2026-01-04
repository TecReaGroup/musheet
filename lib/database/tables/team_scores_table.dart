import 'package:drift/drift.dart';

/// TeamScore table - independent from personal Score
/// Per TEAM_SYNC_LOGIC.md: Team data uses copy mode, not reference mode
@DataClassName('TeamScoreEntity')
class TeamScores extends Table {
  TextColumn get id => text()();
  IntColumn get teamId => integer()();
  TextColumn get title => text()();
  TextColumn get composer => text()();
  IntColumn get bpm => integer().withDefault(const Constant(120))();
  IntColumn get createdById => integer()();

  // Source tracking (nullable - null means directly created in team)
  IntColumn get sourceScoreId => integer().nullable()();

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
