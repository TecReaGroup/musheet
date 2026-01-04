import 'package:drift/drift.dart';

/// TeamSetlist table - independent from personal Setlist
/// Per TEAM_SYNC_LOGIC.md: Team data uses copy mode, not reference mode
@DataClassName('TeamSetlistEntity')
class TeamSetlists extends Table {
  TextColumn get id => text()();
  IntColumn get teamId => integer()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get createdById => integer()();

  // Source tracking (nullable - null means directly created in team)
  IntColumn get sourceSetlistId => integer().nullable()();

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
