import 'package:drift/drift.dart';

@DataClassName('SetlistEntity')
class Setlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  DateTimeColumn get dateCreated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}