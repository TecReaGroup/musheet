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

abstract class InstrumentScore
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  InstrumentScore._({
    this.id,
    required this.scoreId,
    required this.instrumentName,
    this.pdfPath,
    this.pdfHash,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstrumentScore({
    int? id,
    required int scoreId,
    required String instrumentName,
    String? pdfPath,
    String? pdfHash,
    required int orderIndex,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _InstrumentScoreImpl;

  factory InstrumentScore.fromJson(Map<String, dynamic> jsonSerialization) {
    return InstrumentScore(
      id: jsonSerialization['id'] as int?,
      scoreId: jsonSerialization['scoreId'] as int,
      instrumentName: jsonSerialization['instrumentName'] as String,
      pdfPath: jsonSerialization['pdfPath'] as String?,
      pdfHash: jsonSerialization['pdfHash'] as String?,
      orderIndex: jsonSerialization['orderIndex'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = InstrumentScoreTable();

  static const db = InstrumentScoreRepository._();

  @override
  int? id;

  int scoreId;

  String instrumentName;

  String? pdfPath;

  String? pdfHash;

  int orderIndex;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [InstrumentScore]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  InstrumentScore copyWith({
    int? id,
    int? scoreId,
    String? instrumentName,
    String? pdfPath,
    String? pdfHash,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InstrumentScore',
      if (id != null) 'id': id,
      'scoreId': scoreId,
      'instrumentName': instrumentName,
      if (pdfPath != null) 'pdfPath': pdfPath,
      if (pdfHash != null) 'pdfHash': pdfHash,
      'orderIndex': orderIndex,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'InstrumentScore',
      if (id != null) 'id': id,
      'scoreId': scoreId,
      'instrumentName': instrumentName,
      if (pdfPath != null) 'pdfPath': pdfPath,
      if (pdfHash != null) 'pdfHash': pdfHash,
      'orderIndex': orderIndex,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static InstrumentScoreInclude include() {
    return InstrumentScoreInclude._();
  }

  static InstrumentScoreIncludeList includeList({
    _i1.WhereExpressionBuilder<InstrumentScoreTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<InstrumentScoreTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<InstrumentScoreTable>? orderByList,
    InstrumentScoreInclude? include,
  }) {
    return InstrumentScoreIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(InstrumentScore.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(InstrumentScore.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _InstrumentScoreImpl extends InstrumentScore {
  _InstrumentScoreImpl({
    int? id,
    required int scoreId,
    required String instrumentName,
    String? pdfPath,
    String? pdfHash,
    required int orderIndex,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         scoreId: scoreId,
         instrumentName: instrumentName,
         pdfPath: pdfPath,
         pdfHash: pdfHash,
         orderIndex: orderIndex,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [InstrumentScore]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  InstrumentScore copyWith({
    Object? id = _Undefined,
    int? scoreId,
    String? instrumentName,
    Object? pdfPath = _Undefined,
    Object? pdfHash = _Undefined,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstrumentScore(
      id: id is int? ? id : this.id,
      scoreId: scoreId ?? this.scoreId,
      instrumentName: instrumentName ?? this.instrumentName,
      pdfPath: pdfPath is String? ? pdfPath : this.pdfPath,
      pdfHash: pdfHash is String? ? pdfHash : this.pdfHash,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class InstrumentScoreUpdateTable extends _i1.UpdateTable<InstrumentScoreTable> {
  InstrumentScoreUpdateTable(super.table);

  _i1.ColumnValue<int, int> scoreId(int value) => _i1.ColumnValue(
    table.scoreId,
    value,
  );

  _i1.ColumnValue<String, String> instrumentName(String value) =>
      _i1.ColumnValue(
        table.instrumentName,
        value,
      );

  _i1.ColumnValue<String, String> pdfPath(String? value) => _i1.ColumnValue(
    table.pdfPath,
    value,
  );

  _i1.ColumnValue<String, String> pdfHash(String? value) => _i1.ColumnValue(
    table.pdfHash,
    value,
  );

  _i1.ColumnValue<int, int> orderIndex(int value) => _i1.ColumnValue(
    table.orderIndex,
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
}

class InstrumentScoreTable extends _i1.Table<int?> {
  InstrumentScoreTable({super.tableRelation})
    : super(tableName: 'instrument_scores') {
    updateTable = InstrumentScoreUpdateTable(this);
    scoreId = _i1.ColumnInt(
      'scoreId',
      this,
    );
    instrumentName = _i1.ColumnString(
      'instrumentName',
      this,
    );
    pdfPath = _i1.ColumnString(
      'pdfPath',
      this,
    );
    pdfHash = _i1.ColumnString(
      'pdfHash',
      this,
    );
    orderIndex = _i1.ColumnInt(
      'orderIndex',
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
  }

  late final InstrumentScoreUpdateTable updateTable;

  late final _i1.ColumnInt scoreId;

  late final _i1.ColumnString instrumentName;

  late final _i1.ColumnString pdfPath;

  late final _i1.ColumnString pdfHash;

  late final _i1.ColumnInt orderIndex;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    scoreId,
    instrumentName,
    pdfPath,
    pdfHash,
    orderIndex,
    createdAt,
    updatedAt,
  ];
}

class InstrumentScoreInclude extends _i1.IncludeObject {
  InstrumentScoreInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => InstrumentScore.t;
}

class InstrumentScoreIncludeList extends _i1.IncludeList {
  InstrumentScoreIncludeList._({
    _i1.WhereExpressionBuilder<InstrumentScoreTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(InstrumentScore.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => InstrumentScore.t;
}

class InstrumentScoreRepository {
  const InstrumentScoreRepository._();

  /// Returns a list of [InstrumentScore]s matching the given query parameters.
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
  Future<List<InstrumentScore>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<InstrumentScoreTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<InstrumentScoreTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<InstrumentScoreTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<InstrumentScore>(
      where: where?.call(InstrumentScore.t),
      orderBy: orderBy?.call(InstrumentScore.t),
      orderByList: orderByList?.call(InstrumentScore.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [InstrumentScore] matching the given query parameters.
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
  Future<InstrumentScore?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<InstrumentScoreTable>? where,
    int? offset,
    _i1.OrderByBuilder<InstrumentScoreTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<InstrumentScoreTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<InstrumentScore>(
      where: where?.call(InstrumentScore.t),
      orderBy: orderBy?.call(InstrumentScore.t),
      orderByList: orderByList?.call(InstrumentScore.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [InstrumentScore] by its [id] or null if no such row exists.
  Future<InstrumentScore?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<InstrumentScore>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [InstrumentScore]s in the list and returns the inserted rows.
  ///
  /// The returned [InstrumentScore]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<InstrumentScore>> insert(
    _i1.Session session,
    List<InstrumentScore> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<InstrumentScore>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [InstrumentScore] and returns the inserted row.
  ///
  /// The returned [InstrumentScore] will have its `id` field set.
  Future<InstrumentScore> insertRow(
    _i1.Session session,
    InstrumentScore row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<InstrumentScore>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [InstrumentScore]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<InstrumentScore>> update(
    _i1.Session session,
    List<InstrumentScore> rows, {
    _i1.ColumnSelections<InstrumentScoreTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<InstrumentScore>(
      rows,
      columns: columns?.call(InstrumentScore.t),
      transaction: transaction,
    );
  }

  /// Updates a single [InstrumentScore]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<InstrumentScore> updateRow(
    _i1.Session session,
    InstrumentScore row, {
    _i1.ColumnSelections<InstrumentScoreTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<InstrumentScore>(
      row,
      columns: columns?.call(InstrumentScore.t),
      transaction: transaction,
    );
  }

  /// Updates a single [InstrumentScore] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<InstrumentScore?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<InstrumentScoreUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<InstrumentScore>(
      id,
      columnValues: columnValues(InstrumentScore.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [InstrumentScore]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<InstrumentScore>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<InstrumentScoreUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<InstrumentScoreTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<InstrumentScoreTable>? orderBy,
    _i1.OrderByListBuilder<InstrumentScoreTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<InstrumentScore>(
      columnValues: columnValues(InstrumentScore.t.updateTable),
      where: where(InstrumentScore.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(InstrumentScore.t),
      orderByList: orderByList?.call(InstrumentScore.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [InstrumentScore]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<InstrumentScore>> delete(
    _i1.Session session,
    List<InstrumentScore> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<InstrumentScore>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [InstrumentScore].
  Future<InstrumentScore> deleteRow(
    _i1.Session session,
    InstrumentScore row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<InstrumentScore>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<InstrumentScore>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<InstrumentScoreTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<InstrumentScore>(
      where: where(InstrumentScore.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<InstrumentScoreTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<InstrumentScore>(
      where: where?.call(InstrumentScore.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
