import 'package:drift/drift.dart';

@DataClassName('ScoreEntity')
class Scores extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get composer => text()();
  IntColumn get bpm => integer().withDefault(const Constant(120))();
  DateTimeColumn get dateAdded => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}