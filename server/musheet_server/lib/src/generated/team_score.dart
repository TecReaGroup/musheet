/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class TeamScore
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  TeamScore._({
    this.id,
    required this.teamId,
    required this.scoreId,
    required this.sharedById,
    required this.sharedAt,
  });

  factory TeamScore({
    int? id,
    required int teamId,
    required int scoreId,
    required int sharedById,
    required DateTime sharedAt,
  }) = _TeamScoreImpl;

  factory TeamScore.fromJson(Map<String, dynamic> jsonSerialization) {
    return TeamScore(
      id: jsonSerialization['id'] as int?,
      teamId: jsonSerialization['teamId'] as int,
      scoreId: jsonSerialization['scoreId'] as int,
      sharedById: jsonSerialization['sharedById'] as int,
      sharedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['sharedAt'],
      ),
    );
  }

  static final t = TeamScoreTable();

  static const db = TeamScoreRepository._();

  @override
  int? id;

  int teamId;

  int scoreId;

  int sharedById;

  DateTime sharedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [TeamScore]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamScore copyWith({
    int? id,
    int? teamId,
    int? scoreId,
    int? sharedById,
    DateTime? sharedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamScore',
      if (id != null) 'id': id,
      'teamId': teamId,
      'scoreId': scoreId,
      'sharedById': sharedById,
      'sharedAt': sharedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TeamScore',
      if (id != null) 'id': id,
      'teamId': teamId,
      'scoreId': scoreId,
      'sharedById': sharedById,
      'sharedAt': sharedAt.toJson(),
    };
  }

  static TeamScoreInclude include() {
    return TeamScoreInclude._();
  }

  static TeamScoreIncludeList includeList({
    _i1.WhereExpressionBuilder<TeamScoreTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TeamScoreTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TeamScoreTable>? orderByList,
    TeamScoreInclude? include,
  }) {
    return TeamScoreIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TeamScore.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TeamScore.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TeamScoreImpl extends TeamScore {
  _TeamScoreImpl({
    int? id,
    required int teamId,
    required int scoreId,
    required int sharedById,
    required DateTime sharedAt,
  }) : super._(
         id: id,
         teamId: teamId,
         scoreId: scoreId,
         sharedById: sharedById,
         sharedAt: sharedAt,
       );

  /// Returns a shallow copy of this [TeamScore]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamScore copyWith({
    Object? id = _Undefined,
    int? teamId,
    int? scoreId,
    int? sharedById,
    DateTime? sharedAt,
  }) {
    return TeamScore(
      id: id is int? ? id : this.id,
      teamId: teamId ?? this.teamId,
      scoreId: scoreId ?? this.scoreId,
      sharedById: sharedById ?? this.sharedById,
      sharedAt: sharedAt ?? this.sharedAt,
    );
  }
}

class TeamScoreUpdateTable extends _i1.UpdateTable<TeamScoreTable> {
  TeamScoreUpdateTable(super.table);

  _i1.ColumnValue<int, int> teamId(int value) => _i1.ColumnValue(
    table.teamId,
    value,
  );

  _i1.ColumnValue<int, int> scoreId(int value) => _i1.ColumnValue(
    table.scoreId,
    value,
  );

  _i1.ColumnValue<int, int> sharedById(int value) => _i1.ColumnValue(
    table.sharedById,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> sharedAt(DateTime value) =>
      _i1.ColumnValue(
        table.sharedAt,
        value,
      );
}

class TeamScoreTable extends _i1.Table<int?> {
  TeamScoreTable({super.tableRelation}) : super(tableName: 'team_scores') {
    updateTable = TeamScoreUpdateTable(this);
    teamId = _i1.ColumnInt(
      'teamId',
      this,
    );
    scoreId = _i1.ColumnInt(
      'scoreId',
      this,
    );
    sharedById = _i1.ColumnInt(
      'sharedById',
      this,
    );
    sharedAt = _i1.ColumnDateTime(
      'sharedAt',
      this,
    );
  }

  late final TeamScoreUpdateTable updateTable;

  late final _i1.ColumnInt teamId;

  late final _i1.ColumnInt scoreId;

  late final _i1.ColumnInt sharedById;

  late final _i1.ColumnDateTime sharedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    teamId,
    scoreId,
    sharedById,
    sharedAt,
  ];
}

class TeamScoreInclude extends _i1.IncludeObject {
  TeamScoreInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => TeamScore.t;
}

class TeamScoreIncludeList extends _i1.IncludeList {
  TeamScoreIncludeList._({
    _i1.WhereExpressionBuilder<TeamScoreTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TeamScore.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => TeamScore.t;
}

class TeamScoreRepository {
  const TeamScoreRepository._();

  /// Returns a list of [TeamScore]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<TeamScore>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TeamScoreTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TeamScoreTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TeamScoreTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<TeamScore>(
      where: where?.call(TeamScore.t),
      orderBy: orderBy?.call(TeamScore.t),
      orderByList: orderByList?.call(TeamScore.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [TeamScore] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<TeamScore?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TeamScoreTable>? where,
    int? offset,
    _i1.OrderByBuilder<TeamScoreTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TeamScoreTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<TeamScore>(
      where: where?.call(TeamScore.t),
      orderBy: orderBy?.call(TeamScore.t),
      orderByList: orderByList?.call(TeamScore.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [TeamScore] by its [id] or null if no such row exists.
  Future<TeamScore?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<TeamScore>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [TeamScore]s in the list and returns the inserted rows.
  ///
  /// The returned [TeamScore]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<TeamScore>> insert(
    _i1.Session session,
    List<TeamScore> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<TeamScore>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [TeamScore] and returns the inserted row.
  ///
  /// The returned [TeamScore] will have its `id` field set.
  Future<TeamScore> insertRow(
    _i1.Session session,
    TeamScore row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TeamScore>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TeamScore]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TeamScore>> update(
    _i1.Session session,
    List<TeamScore> rows, {
    _i1.ColumnSelections<TeamScoreTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TeamScore>(
      rows,
      columns: columns?.call(TeamScore.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TeamScore]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TeamScore> updateRow(
    _i1.Session session,
    TeamScore row, {
    _i1.ColumnSelections<TeamScoreTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TeamScore>(
      row,
      columns: columns?.call(TeamScore.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TeamScore] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TeamScore?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<TeamScoreUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<TeamScore>(
      id,
      columnValues: columnValues(TeamScore.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TeamScore]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<TeamScore>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<TeamScoreUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TeamScoreTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TeamScoreTable>? orderBy,
    _i1.OrderByListBuilder<TeamScoreTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<TeamScore>(
      columnValues: columnValues(TeamScore.t.updateTable),
      where: where(TeamScore.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TeamScore.t),
      orderByList: orderByList?.call(TeamScore.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [TeamScore]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TeamScore>> delete(
    _i1.Session session,
    List<TeamScore> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TeamScore>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TeamScore].
  Future<TeamScore> deleteRow(
    _i1.Session session,
    TeamScore row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TeamScore>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TeamScore>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TeamScoreTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TeamScore>(
      where: where(TeamScore.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TeamScoreTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TeamScore>(
      where: where?.call(TeamScore.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
