import 'package:drift/drift.dart';

/// Unified Score table for both user and team scopes
/// Per sync_logic.md: scopeType + scopeId distinguishes user vs team data
@DataClassName('ScoreEntity')
class Scores extends Table {
  TextColumn get id => text()();

  // Scope fields - determines if this is user or team data
  TextColumn get scopeType => text().withDefault(const Constant('user'))(); // 'user' or 'team'
  IntColumn get scopeId => integer()(); // userId for 'user' scope, teamId for 'team' scope

  TextColumn get title => text()();
  TextColumn get composer => text()();
  IntColumn get bpm => integer().withDefault(const Constant(120))();
  DateTimeColumn get createdAt => dateTime()();

  // Team-specific fields (nullable for user scope)
  IntColumn get createdById => integer().nullable()(); // Who created this (for team scores)
  IntColumn get sourceScoreId => integer().nullable()(); // Original score if copied

  // Sync fields (aligned with sync_logic.md)
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get serverId => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
