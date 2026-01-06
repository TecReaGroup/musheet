import 'package:drift/drift.dart';

/// Unified Setlist table for both user and team scopes
/// Per sync_logic.md: scopeType + scopeId distinguishes user vs team data
@DataClassName('SetlistEntity')
class Setlists extends Table {
  TextColumn get id => text()();

  // Scope fields - determines if this is user or team data
  TextColumn get scopeType => text().withDefault(const Constant('user'))(); // 'user' or 'team'
  IntColumn get scopeId => integer()(); // userId for 'user' scope, teamId for 'team' scope

  TextColumn get name => text()();
  TextColumn get description => text()();
  DateTimeColumn get createdAt => dateTime()();

  // Team-specific fields (nullable for user scope)
  IntColumn get createdById => integer().nullable()(); // Who created this (for team setlists)
  IntColumn get sourceSetlistId => integer().nullable()(); // Original setlist if copied

  // Sync fields (aligned with sync_logic.md)
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get serverId => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
