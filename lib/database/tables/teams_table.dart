import 'package:drift/drift.dart';

/// Teams table - basic team info cached locally
@DataClassName('TeamEntity')
class Teams extends Table {
  TextColumn get id => text()();
  IntColumn get serverId => integer()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
