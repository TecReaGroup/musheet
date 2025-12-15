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

abstract class Annotation
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Annotation._({
    this.id,
    required this.instrumentScoreId,
    required this.userId,
    required this.pageNumber,
    required this.type,
    required this.data,
    required this.positionX,
    required this.positionY,
    this.width,
    this.height,
    this.color,
    this.vectorClock,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Annotation({
    int? id,
    required int instrumentScoreId,
    required int userId,
    required int pageNumber,
    required String type,
    required String data,
    required double positionX,
    required double positionY,
    double? width,
    double? height,
    String? color,
    String? vectorClock,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AnnotationImpl;

  factory Annotation.fromJson(Map<String, dynamic> jsonSerialization) {
    return Annotation(
      id: jsonSerialization['id'] as int?,
      instrumentScoreId: jsonSerialization['instrumentScoreId'] as int,
      userId: jsonSerialization['userId'] as int,
      pageNumber: jsonSerialization['pageNumber'] as int,
      type: jsonSerialization['type'] as String,
      data: jsonSerialization['data'] as String,
      positionX: (jsonSerialization['positionX'] as num).toDouble(),
      positionY: (jsonSerialization['positionY'] as num).toDouble(),
      width: (jsonSerialization['width'] as num?)?.toDouble(),
      height: (jsonSerialization['height'] as num?)?.toDouble(),
      color: jsonSerialization['color'] as String?,
      vectorClock: jsonSerialization['vectorClock'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = AnnotationTable();

  static const db = AnnotationRepository._();

  @override
  int? id;

  int instrumentScoreId;

  int userId;

  int pageNumber;

  String type;

  String data;

  double positionX;

  double positionY;

  double? width;

  double? height;

  String? color;

  String? vectorClock;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Annotation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Annotation copyWith({
    int? id,
    int? instrumentScoreId,
    int? userId,
    int? pageNumber,
    String? type,
    String? data,
    double? positionX,
    double? positionY,
    double? width,
    double? height,
    String? color,
    String? vectorClock,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Annotation',
      if (id != null) 'id': id,
      'instrumentScoreId': instrumentScoreId,
      'userId': userId,
      'pageNumber': pageNumber,
      'type': type,
      'data': data,
      'positionX': positionX,
      'positionY': positionY,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (color != null) 'color': color,
      if (vectorClock != null) 'vectorClock': vectorClock,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Annotation',
      if (id != null) 'id': id,
      'instrumentScoreId': instrumentScoreId,
      'userId': userId,
      'pageNumber': pageNumber,
      'type': type,
      'data': data,
      'positionX': positionX,
      'positionY': positionY,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (color != null) 'color': color,
      if (vectorClock != null) 'vectorClock': vectorClock,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static AnnotationInclude include() {
    return AnnotationInclude._();
  }

  static AnnotationIncludeList includeList({
    _i1.WhereExpressionBuilder<AnnotationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AnnotationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AnnotationTable>? orderByList,
    AnnotationInclude? include,
  }) {
    return AnnotationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Annotation.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Annotation.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AnnotationImpl extends Annotation {
  _AnnotationImpl({
    int? id,
    required int instrumentScoreId,
    required int userId,
    required int pageNumber,
    required String type,
    required String data,
    required double positionX,
    required double positionY,
    double? width,
    double? height,
    String? color,
    String? vectorClock,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         instrumentScoreId: instrumentScoreId,
         userId: userId,
         pageNumber: pageNumber,
         type: type,
         data: data,
         positionX: positionX,
         positionY: positionY,
         width: width,
         height: height,
         color: color,
         vectorClock: vectorClock,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Annotation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Annotation copyWith({
    Object? id = _Undefined,
    int? instrumentScoreId,
    int? userId,
    int? pageNumber,
    String? type,
    String? data,
    double? positionX,
    double? positionY,
    Object? width = _Undefined,
    Object? height = _Undefined,
    Object? color = _Undefined,
    Object? vectorClock = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Annotation(
      id: id is int? ? id : this.id,
      instrumentScoreId: instrumentScoreId ?? this.instrumentScoreId,
      userId: userId ?? this.userId,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      data: data ?? this.data,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      width: width is double? ? width : this.width,
      height: height is double? ? height : this.height,
      color: color is String? ? color : this.color,
      vectorClock: vectorClock is String? ? vectorClock : this.vectorClock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AnnotationUpdateTable extends _i1.UpdateTable<AnnotationTable> {
  AnnotationUpdateTable(super.table);

  _i1.ColumnValue<int, int> instrumentScoreId(int value) => _i1.ColumnValue(
    table.instrumentScoreId,
    value,
  );

  _i1.ColumnValue<int, int> userId(int value) => _i1.ColumnValue(
    table.userId,
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

  _i1.ColumnValue<double, double> width(double? value) => _i1.ColumnValue(
    table.width,
    value,
  );

  _i1.ColumnValue<double, double> height(double? value) => _i1.ColumnValue(
    table.height,
    value,
  );

  _i1.ColumnValue<String, String> color(String? value) => _i1.ColumnValue(
    table.color,
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

class AnnotationTable extends _i1.Table<int?> {
  AnnotationTable({super.tableRelation}) : super(tableName: 'annotations') {
    updateTable = AnnotationUpdateTable(this);
    instrumentScoreId = _i1.ColumnInt(
      'instrumentScoreId',
      this,
    );
    userId = _i1.ColumnInt(
      'userId',
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
    width = _i1.ColumnDouble(
      'width',
      this,
    );
    height = _i1.ColumnDouble(
      'height',
      this,
    );
    color = _i1.ColumnString(
      'color',
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

  late final AnnotationUpdateTable updateTable;

  late final _i1.ColumnInt instrumentScoreId;

  late final _i1.ColumnInt userId;

  late final _i1.ColumnInt pageNumber;

  late final _i1.ColumnString type;

  late final _i1.ColumnString data;

  late final _i1.ColumnDouble positionX;

  late final _i1.ColumnDouble positionY;

  late final _i1.ColumnDouble width;

  late final _i1.ColumnDouble height;

  late final _i1.ColumnString color;

  late final _i1.ColumnString vectorClock;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    instrumentScoreId,
    userId,
    pageNumber,
    type,
    data,
    positionX,
    positionY,
    width,
    height,
    color,
    vectorClock,
    createdAt,
    updatedAt,
  ];
}

class AnnotationInclude extends _i1.IncludeObject {
  AnnotationInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Annotation.t;
}

class AnnotationIncludeList extends _i1.IncludeList {
  AnnotationIncludeList._({
    _i1.WhereExpressionBuilder<AnnotationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Annotation.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Annotation.t;
}

class AnnotationRepository {
  const AnnotationRepository._();

  /// Returns a list of [Annotation]s matching the given query parameters.
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
  Future<List<Annotation>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AnnotationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AnnotationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AnnotationTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Annotation>(
      where: where?.call(Annotation.t),
      orderBy: orderBy?.call(Annotation.t),
      orderByList: orderByList?.call(Annotation.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Annotation] matching the given query parameters.
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
  Future<Annotation?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AnnotationTable>? where,
    int? offset,
    _i1.OrderByBuilder<AnnotationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AnnotationTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Annotation>(
      where: where?.call(Annotation.t),
      orderBy: orderBy?.call(Annotation.t),
      orderByList: orderByList?.call(Annotation.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Annotation] by its [id] or null if no such row exists.
  Future<Annotation?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Annotation>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Annotation]s in the list and returns the inserted rows.
  ///
  /// The returned [Annotation]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Annotation>> insert(
    _i1.Session session,
    List<Annotation> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Annotation>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Annotation] and returns the inserted row.
  ///
  /// The returned [Annotation] will have its `id` field set.
  Future<Annotation> insertRow(
    _i1.Session session,
    Annotation row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Annotation>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Annotation]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Annotation>> update(
    _i1.Session session,
    List<Annotation> rows, {
    _i1.ColumnSelections<AnnotationTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Annotation>(
      rows,
      columns: columns?.call(Annotation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Annotation]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Annotation> updateRow(
    _i1.Session session,
    Annotation row, {
    _i1.ColumnSelections<AnnotationTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Annotation>(
      row,
      columns: columns?.call(Annotation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Annotation] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Annotation?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<AnnotationUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Annotation>(
      id,
      columnValues: columnValues(Annotation.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Annotation]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Annotation>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<AnnotationUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<AnnotationTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AnnotationTable>? orderBy,
    _i1.OrderByListBuilder<AnnotationTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Annotation>(
      columnValues: columnValues(Annotation.t.updateTable),
      where: where(Annotation.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Annotation.t),
      orderByList: orderByList?.call(Annotation.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Annotation]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Annotation>> delete(
    _i1.Session session,
    List<Annotation> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Annotation>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Annotation].
  Future<Annotation> deleteRow(
    _i1.Session session,
    Annotation row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Annotation>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Annotation>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<AnnotationTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Annotation>(
      where: where(Annotation.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AnnotationTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Annotation>(
      where: where?.call(Annotation.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
