import 'package:drift/drift.dart';

/// TeamSyncState table - tracks sync version per team
/// Per TEAM_SYNC_LOGIC.md: Each team has independent teamLibraryVersion
@DataClassName('TeamSyncStateEntity')
class TeamSyncState extends Table {
  IntColumn get teamId => integer()();
  IntColumn get teamLibraryVersion => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {teamId};
}
