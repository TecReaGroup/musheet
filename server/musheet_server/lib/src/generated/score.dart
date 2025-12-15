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

abstract class Score implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Score._({
    this.id,
    required this.userId,
    required this.title,
    this.composer,
    this.bpm,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.version,
    this.syncStatus,
  });

  factory Score({
    int? id,
    required int userId,
    required String title,
    String? composer,
    int? bpm,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required int version,
    String? syncStatus,
  }) = _ScoreImpl;

  factory Score.fromJson(Map<String, dynamic> jsonSerialization) {
    return Score(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      title: jsonSerialization['title'] as String,
      composer: jsonSerialization['composer'] as String?,
      bpm: jsonSerialization['bpm'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
      version: jsonSerialization['version'] as int,
      syncStatus: jsonSerialization['syncStatus'] as String?,
    );
  }

  static final t = ScoreTable();

  static const db = ScoreRepository._();

  @override
  int? id;

  int userId;

  String title;

  String? composer;

  int? bpm;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  int version;

  String? syncStatus;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Score]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Score copyWith({
    int? id,
    int? userId,
    String? title,
    String? composer,
    int? bpm,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
    String? syncStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Score',
      if (id != null) 'id': id,
      'userId': userId,
      'title': title,
      if (composer != null) 'composer': composer,
      if (bpm != null) 'bpm': bpm,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      'version': version,
      if (syncStatus != null) 'syncStatus': syncStatus,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Score',
      if (id != null) 'id': id,
      'userId': userId,
      'title': title,
      if (composer != null) 'composer': composer,
      if (bpm != null) 'bpm': bpm,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      'version': version,
      if (syncStatus != null) 'syncStatus': syncStatus,
    };
  }

  static ScoreInclude include() {
    return ScoreInclude._();
  }

  static ScoreIncludeList includeList({
    _i1.WhereExpressionBuilder<ScoreTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ScoreTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ScoreTable>? orderByList,
    ScoreInclude? include,
  }) {
    return ScoreIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Score.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Score.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ScoreImpl extends Score {
  _ScoreImpl({
    int? id,
    required int userId,
    required String title,
    String? composer,
    int? bpm,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required int version,
    String? syncStatus,
  }) : super._(
         id: id,
         userId: userId,
         title: title,
         composer: composer,
         bpm: bpm,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
         version: version,
         syncStatus: syncStatus,
       );

  /// Returns a shallow copy of this [Score]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Score copyWith({
    Object? id = _Undefined,
    int? userId,
    String? title,
    Object? composer = _Undefined,
    Object? bpm = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
    int? version,
    Object? syncStatus = _Undefined,
  }) {
    return Score(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      composer: composer is String? ? composer : this.composer,
      bpm: bpm is int? ? bpm : this.bpm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
      version: version ?? this.version,
      syncStatus: syncStatus is String? ? syncStatus : this.syncStatus,
    );
  }
}

class ScoreUpdateTable extends _i1.UpdateTable<ScoreTable> {
  ScoreUpdateTable(super.table);

  _i1.ColumnValue<int, int> userId(int value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> title(String value) => _i1.ColumnValue(
    table.title,
    value,
  );

  _i1.ColumnValue<String, String> composer(String? value) => _i1.ColumnValue(
    table.composer,
    value,
  );

  _i1.ColumnValue<int, int> bpm(int? value) => _i1.ColumnValue(
    table.bpm,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> deletedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.deletedAt,
        value,
      );

  _i1.ColumnValue<int, int> version(int value) => _i1.ColumnValue(
    table.version,
    value,
  );

  _i1.ColumnValue<String, String> syncStatus(String? value) => _i1.ColumnValue(
    table.syncStatus,
    value,
  );
}

class ScoreTable extends _i1.Table<int?> {
  ScoreTable({super.tableRelation}) : super(tableName: 'scores') {
    updateTable = ScoreUpdateTable(this);
    userId = _i1.ColumnInt(
      'userId',
      this,
    );
    title = _i1.ColumnString(
      'title',
      this,
    );
    composer = _i1.ColumnString(
      'composer',
      this,
    );
    bpm = _i1.ColumnInt(
      'bpm',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
    deletedAt = _i1.ColumnDateTime(
      'deletedAt',
      this,
    );
    version = _i1.ColumnInt(
      'version',
      this,
    );
    syncStatus = _i1.ColumnString(
      'syncStatus',
      this,
    );
  }

  late final ScoreUpdateTable updateTable;

  late final _i1.ColumnInt userId;

  late final _i1.ColumnString title;

  late final _i1.ColumnString composer;

  late final _i1.ColumnInt bpm;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnDateTime deletedAt;

  late final _i1.ColumnInt version;

  late final _i1.ColumnString syncStatus;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    title,
    composer,
    bpm,
    createdAt,
    updatedAt,
    deletedAt,
    version,
    syncStatus,
  ];
}

class ScoreInclude extends _i1.IncludeObject {
  ScoreInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Score.t;
}

class ScoreIncludeList extends _i1.IncludeList {
  ScoreIncludeList._({
    _i1.WhereExpressionBuilder<ScoreTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Score.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Score.t;
}

class ScoreRepository {
  const ScoreRepository._();

  /// Returns a list of [Score]s matching the given query parameters.
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
  Future<List<Score>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ScoreTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ScoreTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ScoreTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Score>(
      where: where?.call(Score.t),
      orderBy: orderBy?.call(Score.t),
      orderByList: orderByList?.call(Score.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Score] matching the given query parameters.
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
  Future<Score?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ScoreTable>? where,
    int? offset,
    _i1.OrderByBuilder<ScoreTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ScoreTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Score>(
      where: where?.call(Score.t),
      orderBy: orderBy?.call(Score.t),
      orderByList: orderByList?.call(Score.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Score] by its [id] or null if no such row exists.
  Future<Score?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Score>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Score]s in the list and returns the inserted rows.
  ///
  /// The returned [Score]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Score>> insert(
    _i1.Session session,
    List<Score> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Score>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Score] and returns the inserted row.
  ///
  /// The returned [Score] will have its `id` field set.
  Future<Score> insertRow(
    _i1.Session session,
    Score row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Score>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Score]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Score>> update(
    _i1.Session session,
    List<Score> rows, {
    _i1.ColumnSelections<ScoreTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Score>(
      rows,
      columns: columns?.call(Score.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Score]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Score> updateRow(
    _i1.Session session,
    Score row, {
    _i1.ColumnSelections<ScoreTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Score>(
      row,
      columns: columns?.call(Score.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Score] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Score?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<ScoreUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Score>(
      id,
      columnValues: columnValues(Score.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Score]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Score>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<ScoreUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ScoreTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ScoreTable>? orderBy,
    _i1.OrderByListBuilder<ScoreTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Score>(
      columnValues: columnValues(Score.t.updateTable),
      where: where(Score.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Score.t),
      orderByList: orderByList?.call(Score.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Score]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Score>> delete(
    _i1.Session session,
    List<Score> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Score>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Score].
  Future<Score> deleteRow(
    _i1.Session session,
    Score row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Score>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Score>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ScoreTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Score>(
      where: where(Score.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ScoreTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Score>(
      where: where?.call(Score.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
