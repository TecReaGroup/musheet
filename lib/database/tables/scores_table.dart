import 'package:drift/drift.dart';

@DataClassName('ScoreEntity')
class Scores extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get composer => text()();
  IntColumn get bpm => integer().withDefault(const Constant(120))();
  DateTimeColumn get createdAt => dateTime()();

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
