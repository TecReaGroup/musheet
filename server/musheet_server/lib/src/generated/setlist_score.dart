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

abstract class SetlistScore
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  SetlistScore._({
    this.id,
    required this.setlistId,
    required this.scoreId,
    required this.orderIndex,
  });

  factory SetlistScore({
    int? id,
    required int setlistId,
    required int scoreId,
    required int orderIndex,
  }) = _SetlistScoreImpl;

  factory SetlistScore.fromJson(Map<String, dynamic> jsonSerialization) {
    return SetlistScore(
      id: jsonSerialization['id'] as int?,
      setlistId: jsonSerialization['setlistId'] as int,
      scoreId: jsonSerialization['scoreId'] as int,
      orderIndex: jsonSerialization['orderIndex'] as int,
    );
  }

  static final t = SetlistScoreTable();

  static const db = SetlistScoreRepository._();

  @override
  int? id;

  int setlistId;

  int scoreId;

  int orderIndex;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [SetlistScore]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SetlistScore copyWith({
    int? id,
    int? setlistId,
    int? scoreId,
    int? orderIndex,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SetlistScore',
      if (id != null) 'id': id,
      'setlistId': setlistId,
      'scoreId': scoreId,
      'orderIndex': orderIndex,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SetlistScore',
      if (id != null) 'id': id,
      'setlistId': setlistId,
      'scoreId': scoreId,
      'orderIndex': orderIndex,
    };
  }

  static SetlistScoreInclude include() {
    return SetlistScoreInclude._();
  }

  static SetlistScoreIncludeList includeList({
    _i1.WhereExpressionBuilder<SetlistScoreTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SetlistScoreTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SetlistScoreTable>? orderByList,
    SetlistScoreInclude? include,
  }) {
    return SetlistScoreIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SetlistScore.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SetlistScore.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SetlistScoreImpl extends SetlistScore {
  _SetlistScoreImpl({
    int? id,
    required int setlistId,
    required int scoreId,
    required int orderIndex,
  }) : super._(
         id: id,
         setlistId: setlistId,
         scoreId: scoreId,
         orderIndex: orderIndex,
       );

  /// Returns a shallow copy of this [SetlistScore]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SetlistScore copyWith({
    Object? id = _Undefined,
    int? setlistId,
    int? scoreId,
    int? orderIndex,
  }) {
    return SetlistScore(
      id: id is int? ? id : this.id,
      setlistId: setlistId ?? this.setlistId,
      scoreId: scoreId ?? this.scoreId,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}

class SetlistScoreUpdateTable extends _i1.UpdateTable<SetlistScoreTable> {
  SetlistScoreUpdateTable(super.table);

  _i1.ColumnValue<int, int> setlistId(int value) => _i1.ColumnValue(
    table.setlistId,
    value,
  );

  _i1.ColumnValue<int, int> scoreId(int value) => _i1.ColumnValue(
    table.scoreId,
    value,
  );

  _i1.ColumnValue<int, int> orderIndex(int value) => _i1.ColumnValue(
    table.orderIndex,
    value,
  );
}

class SetlistScoreTable extends _i1.Table<int?> {
  SetlistScoreTable({super.tableRelation})
    : super(tableName: 'setlist_scores') {
    updateTable = SetlistScoreUpdateTable(this);
    setlistId = _i1.ColumnInt(
      'setlistId',
      this,
    );
    scoreId = _i1.ColumnInt(
      'scoreId',
      this,
    );
    orderIndex = _i1.ColumnInt(
      'orderIndex',
      this,
    );
  }

  late final SetlistScoreUpdateTable updateTable;

  late final _i1.ColumnInt setlistId;

  late final _i1.ColumnInt scoreId;

  late final _i1.ColumnInt orderIndex;

  @override
  List<_i1.Column> get columns => [
    id,
    setlistId,
    scoreId,
    orderIndex,
  ];
}

class SetlistScoreInclude extends _i1.IncludeObject {
  SetlistScoreInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => SetlistScore.t;
}

class SetlistScoreIncludeList extends _i1.IncludeList {
  SetlistScoreIncludeList._({
    _i1.WhereExpressionBuilder<SetlistScoreTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SetlistScore.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => SetlistScore.t;
}

class SetlistScoreRepository {
  const SetlistScoreRepository._();

  /// Returns a list of [SetlistScore]s matching the given query parameters.
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
  Future<List<SetlistScore>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SetlistScoreTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SetlistScoreTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SetlistScoreTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<SetlistScore>(
      where: where?.call(SetlistScore.t),
      orderBy: orderBy?.call(SetlistScore.t),
      orderByList: orderByList?.call(SetlistScore.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [SetlistScore] matching the given query parameters.
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
  Future<SetlistScore?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SetlistScoreTable>? where,
    int? offset,
    _i1.OrderByBuilder<SetlistScoreTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SetlistScoreTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<SetlistScore>(
      where: where?.call(SetlistScore.t),
      orderBy: orderBy?.call(SetlistScore.t),
      orderByList: orderByList?.call(SetlistScore.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [SetlistScore] by its [id] or null if no such row exists.
  Future<SetlistScore?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<SetlistScore>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [SetlistScore]s in the list and returns the inserted rows.
  ///
  /// The returned [SetlistScore]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<SetlistScore>> insert(
    _i1.Session session,
    List<SetlistScore> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<SetlistScore>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [SetlistScore] and returns the inserted row.
  ///
  /// The returned [SetlistScore] will have its `id` field set.
  Future<SetlistScore> insertRow(
    _i1.Session session,
    SetlistScore row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SetlistScore>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SetlistScore]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SetlistScore>> update(
    _i1.Session session,
    List<SetlistScore> rows, {
    _i1.ColumnSelections<SetlistScoreTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SetlistScore>(
      rows,
      columns: columns?.call(SetlistScore.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SetlistScore]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SetlistScore> updateRow(
    _i1.Session session,
    SetlistScore row, {
    _i1.ColumnSelections<SetlistScoreTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SetlistScore>(
      row,
      columns: columns?.call(SetlistScore.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SetlistScore] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SetlistScore?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<SetlistScoreUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<SetlistScore>(
      id,
      columnValues: columnValues(SetlistScore.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SetlistScore]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<SetlistScore>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<SetlistScoreUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SetlistScoreTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SetlistScoreTable>? orderBy,
    _i1.OrderByListBuilder<SetlistScoreTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<SetlistScore>(
      columnValues: columnValues(SetlistScore.t.updateTable),
      where: where(SetlistScore.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SetlistScore.t),
      orderByList: orderByList?.call(SetlistScore.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [SetlistScore]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SetlistScore>> delete(
    _i1.Session session,
    List<SetlistScore> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SetlistScore>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SetlistScore].
  Future<SetlistScore> deleteRow(
    _i1.Session session,
    SetlistScore row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SetlistScore>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SetlistScore>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<SetlistScoreTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SetlistScore>(
      where: where(SetlistScore.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SetlistScoreTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SetlistScore>(
      where: where?.call(SetlistScore.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
