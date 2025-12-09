import 'package:drift/drift.dart';
import 'setlists_table.dart';
import 'scores_table.dart';

@DataClassName('SetlistScoreEntity')
class SetlistScores extends Table {
  TextColumn get setlistId => text().references(Setlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get scoreId => text().references(Scores, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderIndex => integer()();

  @override
  Set<Column> get primaryKey => {setlistId, scoreId};
}