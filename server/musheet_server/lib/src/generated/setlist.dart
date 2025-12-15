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

abstract class Setlist
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Setlist._({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Setlist({
    int? id,
    required int userId,
    required String name,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _SetlistImpl;

  factory Setlist.fromJson(Map<String, dynamic> jsonSerialization) {
    return Setlist(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
    );
  }

  static final t = SetlistTable();

  static const db = SetlistRepository._();

  @override
  int? id;

  int userId;

  String name;

  String? description;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? deletedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Setlist]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Setlist copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Setlist',
      if (id != null) 'id': id,
      'userId': userId,
      'name': name,
      if (description != null) 'description': description,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Setlist',
      if (id != null) 'id': id,
      'userId': userId,
      'name': name,
      if (description != null) 'description': description,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
    };
  }

  static SetlistInclude include() {
    return SetlistInclude._();
  }

  static SetlistIncludeList includeList({
    _i1.WhereExpressionBuilder<SetlistTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SetlistTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SetlistTable>? orderByList,
    SetlistInclude? include,
  }) {
    return SetlistIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Setlist.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Setlist.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SetlistImpl extends Setlist {
  _SetlistImpl({
    int? id,
    required int userId,
    required String name,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super._(
         id: id,
         userId: userId,
         name: name,
         description: description,
         createdAt: createdAt,
         updatedAt: updatedAt,
         deletedAt: deletedAt,
       );

  /// Returns a shallow copy of this [Setlist]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Setlist copyWith({
    Object? id = _Undefined,
    int? userId,
    String? name,
    Object? description = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _Undefined,
  }) {
    return Setlist(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt is DateTime? ? deletedAt : this.deletedAt,
    );
  }
}

class SetlistUpdateTable extends _i1.UpdateTable<SetlistTable> {
  SetlistUpdateTable(super.table);

  _i1.ColumnValue<int, int> userId(int value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> description(String? value) => _i1.ColumnValue(
    table.description,
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
}

class SetlistTable extends _i1.Table<int?> {
  SetlistTable({super.tableRelation}) : super(tableName: 'setlists') {
    updateTable = SetlistUpdateTable(this);
    userId = _i1.ColumnInt(
      'userId',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    description = _i1.ColumnString(
      'description',
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
  }

  late final SetlistUpdateTable updateTable;

  late final _i1.ColumnInt userId;

  late final _i1.ColumnString name;

  late final _i1.ColumnString description;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  late final _i1.ColumnDateTime deletedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    name,
    description,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class SetlistInclude extends _i1.IncludeObject {
  SetlistInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Setlist.t;
}

class SetlistIncludeList extends _i1.IncludeList {
  SetlistIncludeList._({
    _i1.WhereExpressionBuilder<SetlistTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Setlist.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Setlist.t;
}

class SetlistRepository {
  const SetlistRepository._();

  /// Returns a list of [Setlist]s matching the given query parameters.
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
  Future<List<Setlist>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SetlistTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SetlistTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SetlistTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Setlist>(
      where: where?.call(Setlist.t),
      orderBy: orderBy?.call(Setlist.t),
      orderByList: orderByList?.call(Setlist.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Setlist] matching the given query parameters.
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
  Future<Setlist?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SetlistTable>? where,
    int? offset,
    _i1.OrderByBuilder<SetlistTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SetlistTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Setlist>(
      where: where?.call(Setlist.t),
      orderBy: orderBy?.call(Setlist.t),
      orderByList: orderByList?.call(Setlist.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Setlist] by its [id] or null if no such row exists.
  Future<Setlist?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Setlist>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Setlist]s in the list and returns the inserted rows.
  ///
  /// The returned [Setlist]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Setlist>> insert(
    _i1.Session session,
    List<Setlist> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Setlist>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Setlist] and returns the inserted row.
  ///
  /// The returned [Setlist] will have its `id` field set.
  Future<Setlist> insertRow(
    _i1.Session session,
    Setlist row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Setlist>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Setlist]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Setlist>> update(
    _i1.Session session,
    List<Setlist> rows, {
    _i1.ColumnSelections<SetlistTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Setlist>(
      rows,
      columns: columns?.call(Setlist.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Setlist]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Setlist> updateRow(
    _i1.Session session,
    Setlist row, {
    _i1.ColumnSelections<SetlistTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Setlist>(
      row,
      columns: columns?.call(Setlist.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Setlist] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Setlist?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<SetlistUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Setlist>(
      id,
      columnValues: columnValues(Setlist.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Setlist]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Setlist>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<SetlistUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SetlistTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SetlistTable>? orderBy,
    _i1.OrderByListBuilder<SetlistTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Setlist>(
      columnValues: columnValues(Setlist.t.updateTable),
      where: where(Setlist.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Setlist.t),
      orderByList: orderByList?.call(Setlist.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Setlist]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Setlist>> delete(
    _i1.Session session,
    List<Setlist> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Setlist>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Setlist].
  Future<Setlist> deleteRow(
    _i1.Session session,
    Setlist row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Setlist>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Setlist>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<SetlistTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Setlist>(
      where: where(Setlist.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SetlistTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Setlist>(
      where: where?.call(Setlist.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
