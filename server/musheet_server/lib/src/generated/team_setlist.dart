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

abstract class TeamSetlist
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  TeamSetlist._({
    this.id,
    required this.teamId,
    required this.setlistId,
    required this.sharedById,
    required this.sharedAt,
  });

  factory TeamSetlist({
    int? id,
    required int teamId,
    required int setlistId,
    required int sharedById,
    required DateTime sharedAt,
  }) = _TeamSetlistImpl;

  factory TeamSetlist.fromJson(Map<String, dynamic> jsonSerialization) {
    return TeamSetlist(
      id: jsonSerialization['id'] as int?,
      teamId: jsonSerialization['teamId'] as int,
      setlistId: jsonSerialization['setlistId'] as int,
      sharedById: jsonSerialization['sharedById'] as int,
      sharedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['sharedAt'],
      ),
    );
  }

  static final t = TeamSetlistTable();

  static const db = TeamSetlistRepository._();

  @override
  int? id;

  int teamId;

  int setlistId;

  int sharedById;

  DateTime sharedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [TeamSetlist]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamSetlist copyWith({
    int? id,
    int? teamId,
    int? setlistId,
    int? sharedById,
    DateTime? sharedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamSetlist',
      if (id != null) 'id': id,
      'teamId': teamId,
      'setlistId': setlistId,
      'sharedById': sharedById,
      'sharedAt': sharedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TeamSetlist',
      if (id != null) 'id': id,
      'teamId': teamId,
      'setlistId': setlistId,
      'sharedById': sharedById,
      'sharedAt': sharedAt.toJson(),
    };
  }

  static TeamSetlistInclude include() {
    return TeamSetlistInclude._();
  }

  static TeamSetlistIncludeList includeList({
    _i1.WhereExpressionBuilder<TeamSetlistTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TeamSetlistTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TeamSetlistTable>? orderByList,
    TeamSetlistInclude? include,
  }) {
    return TeamSetlistIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TeamSetlist.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TeamSetlist.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TeamSetlistImpl extends TeamSetlist {
  _TeamSetlistImpl({
    int? id,
    required int teamId,
    required int setlistId,
    required int sharedById,
    required DateTime sharedAt,
  }) : super._(
         id: id,
         teamId: teamId,
         setlistId: setlistId,
         sharedById: sharedById,
         sharedAt: sharedAt,
       );

  /// Returns a shallow copy of this [TeamSetlist]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamSetlist copyWith({
    Object? id = _Undefined,
    int? teamId,
    int? setlistId,
    int? sharedById,
    DateTime? sharedAt,
  }) {
    return TeamSetlist(
      id: id is int? ? id : this.id,
      teamId: teamId ?? this.teamId,
      setlistId: setlistId ?? this.setlistId,
      sharedById: sharedById ?? this.sharedById,
      sharedAt: sharedAt ?? this.sharedAt,
    );
  }
}

class TeamSetlistUpdateTable extends _i1.UpdateTable<TeamSetlistTable> {
  TeamSetlistUpdateTable(super.table);

  _i1.ColumnValue<int, int> teamId(int value) => _i1.ColumnValue(
    table.teamId,
    value,
  );

  _i1.ColumnValue<int, int> setlistId(int value) => _i1.ColumnValue(
    table.setlistId,
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

class TeamSetlistTable extends _i1.Table<int?> {
  TeamSetlistTable({super.tableRelation}) : super(tableName: 'team_setlists') {
    updateTable = TeamSetlistUpdateTable(this);
    teamId = _i1.ColumnInt(
      'teamId',
      this,
    );
    setlistId = _i1.ColumnInt(
      'setlistId',
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

  late final TeamSetlistUpdateTable updateTable;

  late final _i1.ColumnInt teamId;

  late final _i1.ColumnInt setlistId;

  late final _i1.ColumnInt sharedById;

  late final _i1.ColumnDateTime sharedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    teamId,
    setlistId,
    sharedById,
    sharedAt,
  ];
}

class TeamSetlistInclude extends _i1.IncludeObject {
  TeamSetlistInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => TeamSetlist.t;
}

class TeamSetlistIncludeList extends _i1.IncludeList {
  TeamSetlistIncludeList._({
    _i1.WhereExpressionBuilder<TeamSetlistTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TeamSetlist.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => TeamSetlist.t;
}

class TeamSetlistRepository {
  const TeamSetlistRepository._();

  /// Returns a list of [TeamSetlist]s matching the given query parameters.
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
  Future<List<TeamSetlist>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TeamSetlistTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TeamSetlistTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TeamSetlistTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<TeamSetlist>(
      where: where?.call(TeamSetlist.t),
      orderBy: orderBy?.call(TeamSetlist.t),
      orderByList: orderByList?.call(TeamSetlist.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [TeamSetlist] matching the given query parameters.
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
  Future<TeamSetlist?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TeamSetlistTable>? where,
    int? offset,
    _i1.OrderByBuilder<TeamSetlistTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TeamSetlistTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<TeamSetlist>(
      where: where?.call(TeamSetlist.t),
      orderBy: orderBy?.call(TeamSetlist.t),
      orderByList: orderByList?.call(TeamSetlist.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [TeamSetlist] by its [id] or null if no such row exists.
  Future<TeamSetlist?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<TeamSetlist>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [TeamSetlist]s in the list and returns the inserted rows.
  ///
  /// The returned [TeamSetlist]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<TeamSetlist>> insert(
    _i1.Session session,
    List<TeamSetlist> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<TeamSetlist>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [TeamSetlist] and returns the inserted row.
  ///
  /// The returned [TeamSetlist] will have its `id` field set.
  Future<TeamSetlist> insertRow(
    _i1.Session session,
    TeamSetlist row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TeamSetlist>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TeamSetlist]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TeamSetlist>> update(
    _i1.Session session,
    List<TeamSetlist> rows, {
    _i1.ColumnSelections<TeamSetlistTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TeamSetlist>(
      rows,
      columns: columns?.call(TeamSetlist.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TeamSetlist]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TeamSetlist> updateRow(
    _i1.Session session,
    TeamSetlist row, {
    _i1.ColumnSelections<TeamSetlistTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TeamSetlist>(
      row,
      columns: columns?.call(TeamSetlist.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TeamSetlist] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TeamSetlist?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<TeamSetlistUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<TeamSetlist>(
      id,
      columnValues: columnValues(TeamSetlist.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TeamSetlist]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<TeamSetlist>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<TeamSetlistUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TeamSetlistTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TeamSetlistTable>? orderBy,
    _i1.OrderByListBuilder<TeamSetlistTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<TeamSetlist>(
      columnValues: columnValues(TeamSetlist.t.updateTable),
      where: where(TeamSetlist.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TeamSetlist.t),
      orderByList: orderByList?.call(TeamSetlist.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [TeamSetlist]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TeamSetlist>> delete(
    _i1.Session session,
    List<TeamSetlist> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TeamSetlist>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TeamSetlist].
  Future<TeamSetlist> deleteRow(
    _i1.Session session,
    TeamSetlist row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TeamSetlist>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TeamSetlist>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TeamSetlistTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TeamSetlist>(
      where: where(TeamSetlist.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TeamSetlistTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TeamSetlist>(
      where: where?.call(TeamSetlist.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
