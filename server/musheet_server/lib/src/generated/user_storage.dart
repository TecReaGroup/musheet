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

abstract class UserStorage
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  UserStorage._({
    this.id,
    required this.userId,
    required this.usedBytes,
    required this.quotaBytes,
    required this.lastCalculatedAt,
  });

  factory UserStorage({
    int? id,
    required int userId,
    required int usedBytes,
    required int quotaBytes,
    required DateTime lastCalculatedAt,
  }) = _UserStorageImpl;

  factory UserStorage.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserStorage(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      usedBytes: jsonSerialization['usedBytes'] as int,
      quotaBytes: jsonSerialization['quotaBytes'] as int,
      lastCalculatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastCalculatedAt'],
      ),
    );
  }

  static final t = UserStorageTable();

  static const db = UserStorageRepository._();

  @override
  int? id;

  int userId;

  int usedBytes;

  int quotaBytes;

  DateTime lastCalculatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [UserStorage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserStorage copyWith({
    int? id,
    int? userId,
    int? usedBytes,
    int? quotaBytes,
    DateTime? lastCalculatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserStorage',
      if (id != null) 'id': id,
      'userId': userId,
      'usedBytes': usedBytes,
      'quotaBytes': quotaBytes,
      'lastCalculatedAt': lastCalculatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UserStorage',
      if (id != null) 'id': id,
      'userId': userId,
      'usedBytes': usedBytes,
      'quotaBytes': quotaBytes,
      'lastCalculatedAt': lastCalculatedAt.toJson(),
    };
  }

  static UserStorageInclude include() {
    return UserStorageInclude._();
  }

  static UserStorageIncludeList includeList({
    _i1.WhereExpressionBuilder<UserStorageTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserStorageTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserStorageTable>? orderByList,
    UserStorageInclude? include,
  }) {
    return UserStorageIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserStorage.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(UserStorage.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserStorageImpl extends UserStorage {
  _UserStorageImpl({
    int? id,
    required int userId,
    required int usedBytes,
    required int quotaBytes,
    required DateTime lastCalculatedAt,
  }) : super._(
         id: id,
         userId: userId,
         usedBytes: usedBytes,
         quotaBytes: quotaBytes,
         lastCalculatedAt: lastCalculatedAt,
       );

  /// Returns a shallow copy of this [UserStorage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserStorage copyWith({
    Object? id = _Undefined,
    int? userId,
    int? usedBytes,
    int? quotaBytes,
    DateTime? lastCalculatedAt,
  }) {
    return UserStorage(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      usedBytes: usedBytes ?? this.usedBytes,
      quotaBytes: quotaBytes ?? this.quotaBytes,
      lastCalculatedAt: lastCalculatedAt ?? this.lastCalculatedAt,
    );
  }
}

class UserStorageUpdateTable extends _i1.UpdateTable<UserStorageTable> {
  UserStorageUpdateTable(super.table);

  _i1.ColumnValue<int, int> userId(int value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<int, int> usedBytes(int value) => _i1.ColumnValue(
    table.usedBytes,
    value,
  );

  _i1.ColumnValue<int, int> quotaBytes(int value) => _i1.ColumnValue(
    table.quotaBytes,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> lastCalculatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.lastCalculatedAt,
        value,
      );
}

class UserStorageTable extends _i1.Table<int?> {
  UserStorageTable({super.tableRelation}) : super(tableName: 'user_storage') {
    updateTable = UserStorageUpdateTable(this);
    userId = _i1.ColumnInt(
      'userId',
      this,
    );
    usedBytes = _i1.ColumnInt(
      'usedBytes',
      this,
    );
    quotaBytes = _i1.ColumnInt(
      'quotaBytes',
      this,
    );
    lastCalculatedAt = _i1.ColumnDateTime(
      'lastCalculatedAt',
      this,
    );
  }

  late final UserStorageUpdateTable updateTable;

  late final _i1.ColumnInt userId;

  late final _i1.ColumnInt usedBytes;

  late final _i1.ColumnInt quotaBytes;

  late final _i1.ColumnDateTime lastCalculatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    usedBytes,
    quotaBytes,
    lastCalculatedAt,
  ];
}

class UserStorageInclude extends _i1.IncludeObject {
  UserStorageInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => UserStorage.t;
}

class UserStorageIncludeList extends _i1.IncludeList {
  UserStorageIncludeList._({
    _i1.WhereExpressionBuilder<UserStorageTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(UserStorage.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => UserStorage.t;
}

class UserStorageRepository {
  const UserStorageRepository._();

  /// Returns a list of [UserStorage]s matching the given query parameters.
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
  Future<List<UserStorage>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserStorageTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserStorageTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserStorageTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<UserStorage>(
      where: where?.call(UserStorage.t),
      orderBy: orderBy?.call(UserStorage.t),
      orderByList: orderByList?.call(UserStorage.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [UserStorage] matching the given query parameters.
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
  Future<UserStorage?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserStorageTable>? where,
    int? offset,
    _i1.OrderByBuilder<UserStorageTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserStorageTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<UserStorage>(
      where: where?.call(UserStorage.t),
      orderBy: orderBy?.call(UserStorage.t),
      orderByList: orderByList?.call(UserStorage.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [UserStorage] by its [id] or null if no such row exists.
  Future<UserStorage?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<UserStorage>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [UserStorage]s in the list and returns the inserted rows.
  ///
  /// The returned [UserStorage]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<UserStorage>> insert(
    _i1.Session session,
    List<UserStorage> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<UserStorage>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [UserStorage] and returns the inserted row.
  ///
  /// The returned [UserStorage] will have its `id` field set.
  Future<UserStorage> insertRow(
    _i1.Session session,
    UserStorage row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<UserStorage>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [UserStorage]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<UserStorage>> update(
    _i1.Session session,
    List<UserStorage> rows, {
    _i1.ColumnSelections<UserStorageTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<UserStorage>(
      rows,
      columns: columns?.call(UserStorage.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserStorage]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<UserStorage> updateRow(
    _i1.Session session,
    UserStorage row, {
    _i1.ColumnSelections<UserStorageTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<UserStorage>(
      row,
      columns: columns?.call(UserStorage.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserStorage] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<UserStorage?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<UserStorageUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<UserStorage>(
      id,
      columnValues: columnValues(UserStorage.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [UserStorage]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<UserStorage>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<UserStorageUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<UserStorageTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserStorageTable>? orderBy,
    _i1.OrderByListBuilder<UserStorageTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<UserStorage>(
      columnValues: columnValues(UserStorage.t.updateTable),
      where: where(UserStorage.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserStorage.t),
      orderByList: orderByList?.call(UserStorage.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [UserStorage]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<UserStorage>> delete(
    _i1.Session session,
    List<UserStorage> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<UserStorage>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [UserStorage].
  Future<UserStorage> deleteRow(
    _i1.Session session,
    UserStorage row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<UserStorage>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<UserStorage>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<UserStorageTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<UserStorage>(
      where: where(UserStorage.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserStorageTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<UserStorage>(
      where: where?.call(UserStorage.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
