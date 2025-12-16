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

/// User Library
/// Tracks the global library version for each user (Zotero-style)
abstract class UserLibrary
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  UserLibrary._({
    this.id,
    required this.userId,
    required this.libraryVersion,
    required this.lastSyncAt,
    required this.lastModifiedAt,
  });

  factory UserLibrary({
    int? id,
    required int userId,
    required int libraryVersion,
    required DateTime lastSyncAt,
    required DateTime lastModifiedAt,
  }) = _UserLibraryImpl;

  factory UserLibrary.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserLibrary(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      libraryVersion: jsonSerialization['libraryVersion'] as int,
      lastSyncAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSyncAt'],
      ),
      lastModifiedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastModifiedAt'],
      ),
    );
  }

  static final t = UserLibraryTable();

  static const db = UserLibraryRepository._();

  @override
  int? id;

  /// User ID (foreign key to users)
  int userId;

  /// Current library version (increments on any change)
  int libraryVersion;

  /// Last sync timestamp
  DateTime lastSyncAt;

  /// Last modification timestamp
  DateTime lastModifiedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [UserLibrary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserLibrary copyWith({
    int? id,
    int? userId,
    int? libraryVersion,
    DateTime? lastSyncAt,
    DateTime? lastModifiedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserLibrary',
      if (id != null) 'id': id,
      'userId': userId,
      'libraryVersion': libraryVersion,
      'lastSyncAt': lastSyncAt.toJson(),
      'lastModifiedAt': lastModifiedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UserLibrary',
      if (id != null) 'id': id,
      'userId': userId,
      'libraryVersion': libraryVersion,
      'lastSyncAt': lastSyncAt.toJson(),
      'lastModifiedAt': lastModifiedAt.toJson(),
    };
  }

  static UserLibraryInclude include() {
    return UserLibraryInclude._();
  }

  static UserLibraryIncludeList includeList({
    _i1.WhereExpressionBuilder<UserLibraryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserLibraryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserLibraryTable>? orderByList,
    UserLibraryInclude? include,
  }) {
    return UserLibraryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserLibrary.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(UserLibrary.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserLibraryImpl extends UserLibrary {
  _UserLibraryImpl({
    int? id,
    required int userId,
    required int libraryVersion,
    required DateTime lastSyncAt,
    required DateTime lastModifiedAt,
  }) : super._(
         id: id,
         userId: userId,
         libraryVersion: libraryVersion,
         lastSyncAt: lastSyncAt,
         lastModifiedAt: lastModifiedAt,
       );

  /// Returns a shallow copy of this [UserLibrary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserLibrary copyWith({
    Object? id = _Undefined,
    int? userId,
    int? libraryVersion,
    DateTime? lastSyncAt,
    DateTime? lastModifiedAt,
  }) {
    return UserLibrary(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      libraryVersion: libraryVersion ?? this.libraryVersion,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }
}

class UserLibraryUpdateTable extends _i1.UpdateTable<UserLibraryTable> {
  UserLibraryUpdateTable(super.table);

  _i1.ColumnValue<int, int> userId(int value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<int, int> libraryVersion(int value) => _i1.ColumnValue(
    table.libraryVersion,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> lastSyncAt(DateTime value) =>
      _i1.ColumnValue(
        table.lastSyncAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> lastModifiedAt(DateTime value) =>
      _i1.ColumnValue(
        table.lastModifiedAt,
        value,
      );
}

class UserLibraryTable extends _i1.Table<int?> {
  UserLibraryTable({super.tableRelation}) : super(tableName: 'user_libraries') {
    updateTable = UserLibraryUpdateTable(this);
    userId = _i1.ColumnInt(
      'userId',
      this,
    );
    libraryVersion = _i1.ColumnInt(
      'libraryVersion',
      this,
    );
    lastSyncAt = _i1.ColumnDateTime(
      'lastSyncAt',
      this,
    );
    lastModifiedAt = _i1.ColumnDateTime(
      'lastModifiedAt',
      this,
    );
  }

  late final UserLibraryUpdateTable updateTable;

  /// User ID (foreign key to users)
  late final _i1.ColumnInt userId;

  /// Current library version (increments on any change)
  late final _i1.ColumnInt libraryVersion;

  /// Last sync timestamp
  late final _i1.ColumnDateTime lastSyncAt;

  /// Last modification timestamp
  late final _i1.ColumnDateTime lastModifiedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    libraryVersion,
    lastSyncAt,
    lastModifiedAt,
  ];
}

class UserLibraryInclude extends _i1.IncludeObject {
  UserLibraryInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => UserLibrary.t;
}

class UserLibraryIncludeList extends _i1.IncludeList {
  UserLibraryIncludeList._({
    _i1.WhereExpressionBuilder<UserLibraryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(UserLibrary.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => UserLibrary.t;
}

class UserLibraryRepository {
  const UserLibraryRepository._();

  /// Returns a list of [UserLibrary]s matching the given query parameters.
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
  Future<List<UserLibrary>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserLibraryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserLibraryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserLibraryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<UserLibrary>(
      where: where?.call(UserLibrary.t),
      orderBy: orderBy?.call(UserLibrary.t),
      orderByList: orderByList?.call(UserLibrary.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [UserLibrary] matching the given query parameters.
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
  Future<UserLibrary?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserLibraryTable>? where,
    int? offset,
    _i1.OrderByBuilder<UserLibraryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserLibraryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<UserLibrary>(
      where: where?.call(UserLibrary.t),
      orderBy: orderBy?.call(UserLibrary.t),
      orderByList: orderByList?.call(UserLibrary.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [UserLibrary] by its [id] or null if no such row exists.
  Future<UserLibrary?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<UserLibrary>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [UserLibrary]s in the list and returns the inserted rows.
  ///
  /// The returned [UserLibrary]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<UserLibrary>> insert(
    _i1.Session session,
    List<UserLibrary> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<UserLibrary>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [UserLibrary] and returns the inserted row.
  ///
  /// The returned [UserLibrary] will have its `id` field set.
  Future<UserLibrary> insertRow(
    _i1.Session session,
    UserLibrary row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<UserLibrary>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [UserLibrary]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<UserLibrary>> update(
    _i1.Session session,
    List<UserLibrary> rows, {
    _i1.ColumnSelections<UserLibraryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<UserLibrary>(
      rows,
      columns: columns?.call(UserLibrary.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserLibrary]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<UserLibrary> updateRow(
    _i1.Session session,
    UserLibrary row, {
    _i1.ColumnSelections<UserLibraryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<UserLibrary>(
      row,
      columns: columns?.call(UserLibrary.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserLibrary] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<UserLibrary?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<UserLibraryUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<UserLibrary>(
      id,
      columnValues: columnValues(UserLibrary.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [UserLibrary]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<UserLibrary>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<UserLibraryUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<UserLibraryTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserLibraryTable>? orderBy,
    _i1.OrderByListBuilder<UserLibraryTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<UserLibrary>(
      columnValues: columnValues(UserLibrary.t.updateTable),
      where: where(UserLibrary.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserLibrary.t),
      orderByList: orderByList?.call(UserLibrary.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [UserLibrary]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<UserLibrary>> delete(
    _i1.Session session,
    List<UserLibrary> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<UserLibrary>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [UserLibrary].
  Future<UserLibrary> deleteRow(
    _i1.Session session,
    UserLibrary row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<UserLibrary>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<UserLibrary>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<UserLibraryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<UserLibrary>(
      where: where(UserLibrary.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserLibraryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<UserLibrary>(
      where: where?.call(UserLibrary.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
