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

abstract class TeamAnnotation
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  TeamAnnotation._({
    this.id,
    required this.teamScoreId,
    required this.instrumentScoreId,
    required this.pageNumber,
    required this.type,
    required this.data,
    required this.positionX,
    required this.positionY,
    required this.createdBy,
    required this.updatedBy,
    this.vectorClock,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamAnnotation({
    int? id,
    required int teamScoreId,
    required int instrumentScoreId,
    required int pageNumber,
    required String type,
    required String data,
    required double positionX,
    required double positionY,
    required int createdBy,
    required int updatedBy,
    String? vectorClock,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TeamAnnotationImpl;

  factory TeamAnnotation.fromJson(Map<String, dynamic> jsonSerialization) {
    return TeamAnnotation(
      id: jsonSerialization['id'] as int?,
      teamScoreId: jsonSerialization['teamScoreId'] as int,
      instrumentScoreId: jsonSerialization['instrumentScoreId'] as int,
      pageNumber: jsonSerialization['pageNumber'] as int,
      type: jsonSerialization['type'] as String,
      data: jsonSerialization['data'] as String,
      positionX: (jsonSerialization['positionX'] as num).toDouble(),
      positionY: (jsonSerialization['positionY'] as num).toDouble(),
      createdBy: jsonSerialization['createdBy'] as int,
      updatedBy: jsonSerialization['updatedBy'] as int,
      vectorClock: jsonSerialization['vectorClock'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = TeamAnnotationTable();

  static const db = TeamAnnotationRepository._();

  @override
  int? id;

  int teamScoreId;

  int instrumentScoreId;

  int pageNumber;

  String type;

  String data;

  double positionX;

  double positionY;

  int createdBy;

  int updatedBy;

  String? vectorClock;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [TeamAnnotation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TeamAnnotation copyWith({
    int? id,
    int? teamScoreId,
    int? instrumentScoreId,
    int? pageNumber,
    String? type,
    String? data,
    double? positionX,
    double? positionY,
    int? createdBy,
    int? updatedBy,
    String? vectorClock,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TeamAnnotation',
      if (id != null) 'id': id,
      'teamScoreId': teamScoreId,
      'instrumentScoreId': instrumentScoreId,
      'pageNumber': pageNumber,
      'type': type,
      'data': data,
      'positionX': positionX,
      'positionY': positionY,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      if (vectorClock != null) 'vectorClock': vectorClock,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TeamAnnotation',
      if (id != null) 'id': id,
      'teamScoreId': teamScoreId,
      'instrumentScoreId': instrumentScoreId,
      'pageNumber': pageNumber,
      'type': type,
      'data': data,
      'positionX': positionX,
      'positionY': positionY,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      if (vectorClock != null) 'vectorClock': vectorClock,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static TeamAnnotationInclude include() {
    return TeamAnnotationInclude._();
  }

  static TeamAnnotationIncludeList includeList({
    _i1.WhereExpressionBuilder<TeamAnnotationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TeamAnnotationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TeamAnnotationTable>? orderByList,
    TeamAnnotationInclude? include,
  }) {
    return TeamAnnotationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TeamAnnotation.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TeamAnnotation.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TeamAnnotationImpl extends TeamAnnotation {
  _TeamAnnotationImpl({
    int? id,
    required int teamScoreId,
    required int instrumentScoreId,
    required int pageNumber,
    required String type,
    required String data,
    required double positionX,
    required double positionY,
    required int createdBy,
    required int updatedBy,
    String? vectorClock,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         teamScoreId: teamScoreId,
         instrumentScoreId: instrumentScoreId,
         pageNumber: pageNumber,
         type: type,
         data: data,
         positionX: positionX,
         positionY: positionY,
         createdBy: createdBy,
         updatedBy: updatedBy,
         vectorClock: vectorClock,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [TeamAnnotation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TeamAnnotation copyWith({
    Object? id = _Undefined,
    int? teamScoreId,
    int? instrumentScoreId,
    int? pageNumber,
    String? type,
    String? data,
    double? positionX,
    double? positionY,
    int? createdBy,
    int? updatedBy,
    Object? vectorClock = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamAnnotation(
      id: id is int? ? id : this.id,
      teamScoreId: teamScoreId ?? this.teamScoreId,
      instrumentScoreId: instrumentScoreId ?? this.instrumentScoreId,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      data: data ?? this.data,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      vectorClock: vectorClock is String? ? vectorClock : this.vectorClock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TeamAnnotationUpdateTable extends _i1.UpdateTable<TeamAnnotationTable> {
  TeamAnnotationUpdateTable(super.table);

  _i1.ColumnValue<int, int> teamScoreId(int value) => _i1.ColumnValue(
    table.teamScoreId,
    value,
  );

  _i1.ColumnValue<int, int> instrumentScoreId(int value) => _i1.ColumnValue(
    table.instrumentScoreId,
    value,
  );

  _i1.ColumnValue<int, int> pageNumber(int value) => _i1.ColumnValue(
    table.pageNumber,
    value,
  );

  _i1.ColumnValue<String, String> type(String value) => _i1.ColumnValue(
    table.type,
    value,
  );

  _i1.ColumnValue<String, String> data(String value) => _i1.ColumnValue(
    table.data,
    value,
  );

  _i1.ColumnValue<double, double> positionX(double value) => _i1.ColumnValue(
    table.positionX,
    value,
  );

  _i1.ColumnValue<double, double> positionY(double value) => _i1.ColumnValue(
    table.positionY,
    value,
  );

  _i1.ColumnValue<int, int> createdBy(int value) => _i1.ColumnValue(
    table.createdBy,
    value,
  );

  _i1.ColumnValue<int, int> updatedBy(int value) => _i1.ColumnValue(
    table.updatedBy,
    value,
  );

  _i1.ColumnValue<String, String> vectorClock(String? value) => _i1.ColumnValue(
    table.vectorClock,
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

class TeamAnnotationTable extends _i1.Table<int?> {
  TeamAnnotationTable({super.tableRelation})
    : super(tableName: 'team_annotations') {
    updateTable = TeamAnnotationUpdateTable(this);
    teamScoreId = _i1.ColumnInt(
      'teamScoreId',
      this,
    );
    instrumentScoreId = _i1.ColumnInt(
      'instrumentScoreId',
      this,
    );
    pageNumber = _i1.ColumnInt(
      'pageNumber',
      this,
    );
    type = _i1.ColumnString(
      'type',
      this,
    );
    data = _i1.ColumnString(
      'data',
      this,
    );
    positionX = _i1.ColumnDouble(
      'positionX',
      this,
    );
    positionY = _i1.ColumnDouble(
      'positionY',
      this,
    );
    createdBy = _i1.ColumnInt(
      'createdBy',
      this,
    );
    updatedBy = _i1.ColumnInt(
      'updatedBy',
      this,
    );
    vectorClock = _i1.ColumnString(
      'vectorClock',
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

  late final TeamAnnotationUpdateTable updateTable;

  late final _i1.ColumnInt teamScoreId;

  late final _i1.ColumnInt instrumentScoreId;

  late final _i1.ColumnInt pageNumber;

  late final _i1.ColumnString type;

  late final _i1.ColumnString data;

  late final _i1.ColumnDouble positionX;

  late final _i1.ColumnDouble positionY;

  late final _i1.ColumnInt createdBy;

  late final _i1.ColumnInt updatedBy;

  late final _i1.ColumnString vectorClock;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    teamScoreId,
    instrumentScoreId,
    pageNumber,
    type,
    data,
    positionX,
    positionY,
    createdBy,
    updatedBy,
    vectorClock,
    createdAt,
    updatedAt,
  ];
}

class TeamAnnotationInclude extends _i1.IncludeObject {
  TeamAnnotationInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => TeamAnnotation.t;
}

class TeamAnnotationIncludeList extends _i1.IncludeList {
  TeamAnnotationIncludeList._({
    _i1.WhereExpressionBuilder<TeamAnnotationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TeamAnnotation.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => TeamAnnotation.t;
}

class TeamAnnotationRepository {
  const TeamAnnotationRepository._();

  /// Returns a list of [TeamAnnotation]s matching the given query parameters.
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
  Future<List<TeamAnnotation>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TeamAnnotationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TeamAnnotationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TeamAnnotationTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<TeamAnnotation>(
      where: where?.call(TeamAnnotation.t),
      orderBy: orderBy?.call(TeamAnnotation.t),
      orderByList: orderByList?.call(TeamAnnotation.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [TeamAnnotation] matching the given query parameters.
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
  Future<TeamAnnotation?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TeamAnnotationTable>? where,
    int? offset,
    _i1.OrderByBuilder<TeamAnnotationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TeamAnnotationTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<TeamAnnotation>(
      where: where?.call(TeamAnnotation.t),
      orderBy: orderBy?.call(TeamAnnotation.t),
      orderByList: orderByList?.call(TeamAnnotation.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [TeamAnnotation] by its [id] or null if no such row exists.
  Future<TeamAnnotation?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<TeamAnnotation>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [TeamAnnotation]s in the list and returns the inserted rows.
  ///
  /// The returned [TeamAnnotation]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<TeamAnnotation>> insert(
    _i1.Session session,
    List<TeamAnnotation> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<TeamAnnotation>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [TeamAnnotation] and returns the inserted row.
  ///
  /// The returned [TeamAnnotation] will have its `id` field set.
  Future<TeamAnnotation> insertRow(
    _i1.Session session,
    TeamAnnotation row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TeamAnnotation>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TeamAnnotation]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TeamAnnotation>> update(
    _i1.Session session,
    List<TeamAnnotation> rows, {
    _i1.ColumnSelections<TeamAnnotationTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TeamAnnotation>(
      rows,
      columns: columns?.call(TeamAnnotation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TeamAnnotation]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TeamAnnotation> updateRow(
    _i1.Session session,
    TeamAnnotation row, {
    _i1.ColumnSelections<TeamAnnotationTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TeamAnnotation>(
      row,
      columns: columns?.call(TeamAnnotation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TeamAnnotation] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TeamAnnotation?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<TeamAnnotationUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<TeamAnnotation>(
      id,
      columnValues: columnValues(TeamAnnotation.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TeamAnnotation]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<TeamAnnotation>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<TeamAnnotationUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TeamAnnotationTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TeamAnnotationTable>? orderBy,
    _i1.OrderByListBuilder<TeamAnnotationTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<TeamAnnotation>(
      columnValues: columnValues(TeamAnnotation.t.updateTable),
      where: where(TeamAnnotation.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TeamAnnotation.t),
      orderByList: orderByList?.call(TeamAnnotation.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [TeamAnnotation]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TeamAnnotation>> delete(
    _i1.Session session,
    List<TeamAnnotation> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TeamAnnotation>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TeamAnnotation].
  Future<TeamAnnotation> deleteRow(
    _i1.Session session,
    TeamAnnotation row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TeamAnnotation>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TeamAnnotation>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TeamAnnotationTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TeamAnnotation>(
      where: where(TeamAnnotation.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TeamAnnotationTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TeamAnnotation>(
      where: where?.call(TeamAnnotation.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
