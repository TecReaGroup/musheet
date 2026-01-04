import 'package:drift/drift.dart';
import 'teams_table.dart';

/// TeamMembers table - cached team members
/// Per TEAM_SYNC_LOGIC.md: All members have equal role ('member')
@DataClassName('TeamMemberEntity')
class TeamMembers extends Table {
  TextColumn get id => text()();
  TextColumn get teamId => text().references(Teams, #id, onDelete: KeyAction.cascade)();
  IntColumn get userId => integer()();
  TextColumn get username => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('member'))();
  DateTimeColumn get joinedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
