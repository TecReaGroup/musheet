import 'package:drift/drift.dart';

@DataClassName('SetlistEntity')
class Setlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  DateTimeColumn get dateCreated => dateTime()();

  // Sync fields (aligned with sync_logic.md)
  // Note: userId is NOT stored on frontend - backend extracts it from session
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get serverId => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
