import 'package:drift/drift.dart';

@DataClassName('SyncStateEntity')
class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}
