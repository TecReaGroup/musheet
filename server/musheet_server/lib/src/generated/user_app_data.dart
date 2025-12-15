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

abstract class UserAppData
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  UserAppData._({
    this.id,
    required this.userId,
    required this.applicationId,
    this.preferences,
    this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserAppData({
    int? id,
    required int userId,
    required int applicationId,
    String? preferences,
    String? settings,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserAppDataImpl;

  factory UserAppData.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserAppData(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      applicationId: jsonSerialization['applicationId'] as int,
      preferences: jsonSerialization['preferences'] as String?,
      settings: jsonSerialization['settings'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = UserAppDataTable();

  static const db = UserAppDataRepository._();

  @override
  int? id;

  int userId;

  int applicationId;

  String? preferences;

  String? settings;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [UserAppData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserAppData copyWith({
    int? id,
    int? userId,
    int? applicationId,
    String? preferences,
    String? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserAppData',
      if (id != null) 'id': id,
      'userId': userId,
      'applicationId': applicationId,
      if (preferences != null) 'preferences': preferences,
      if (settings != null) 'settings': settings,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UserAppData',
      if (id != null) 'id': id,
      'userId': userId,
      'applicationId': applicationId,
      if (preferences != null) 'preferences': preferences,
      if (settings != null) 'settings': settings,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static UserAppDataInclude include() {
    return UserAppDataInclude._();
  }

  static UserAppDataIncludeList includeList({
    _i1.WhereExpressionBuilder<UserAppDataTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserAppDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserAppDataTable>? orderByList,
    UserAppDataInclude? include,
  }) {
    return UserAppDataIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserAppData.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(UserAppData.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserAppDataImpl extends UserAppData {
  _UserAppDataImpl({
    int? id,
    required int userId,
    required int applicationId,
    String? preferences,
    String? settings,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         userId: userId,
         applicationId: applicationId,
         preferences: preferences,
         settings: settings,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [UserAppData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserAppData copyWith({
    Object? id = _Undefined,
    int? userId,
    int? applicationId,
    Object? preferences = _Undefined,
    Object? settings = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAppData(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      applicationId: applicationId ?? this.applicationId,
      preferences: preferences is String? ? preferences : this.preferences,
      settings: settings is String? ? settings : this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserAppDataUpdateTable extends _i1.UpdateTable<UserAppDataTable> {
  UserAppDataUpdateTable(super.table);

  _i1.ColumnValue<int, int> userId(int value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<int, int> applicationId(int value) => _i1.ColumnValue(
    table.applicationId,
    value,
  );

  _i1.ColumnValue<String, String> preferences(String? value) => _i1.ColumnValue(
    table.preferences,
    value,
  );

  _i1.ColumnValue<String, String> settings(String? value) => _i1.ColumnValue(
    table.settings,
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

class UserAppDataTable extends _i1.Table<int?> {
  UserAppDataTable({super.tableRelation}) : super(tableName: 'user_app_data') {
    updateTable = UserAppDataUpdateTable(this);
    userId = _i1.ColumnInt(
      'userId',
      this,
    );
    applicationId = _i1.ColumnInt(
      'applicationId',
      this,
    );
    preferences = _i1.ColumnString(
      'preferences',
      this,
    );
    settings = _i1.ColumnString(
      'settings',
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

  late final UserAppDataUpdateTable updateTable;

  late final _i1.ColumnInt userId;

  late final _i1.ColumnInt applicationId;

  late final _i1.ColumnString preferences;

  late final _i1.ColumnString settings;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    applicationId,
    preferences,
    settings,
    createdAt,
    updatedAt,
  ];
}

class UserAppDataInclude extends _i1.IncludeObject {
  UserAppDataInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => UserAppData.t;
}

class UserAppDataIncludeList extends _i1.IncludeList {
  UserAppDataIncludeList._({
    _i1.WhereExpressionBuilder<UserAppDataTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(UserAppData.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => UserAppData.t;
}

class UserAppDataRepository {
  const UserAppDataRepository._();

  /// Returns a list of [UserAppData]s matching the given query parameters.
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
  Future<List<UserAppData>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserAppDataTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserAppDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserAppDataTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<UserAppData>(
      where: where?.call(UserAppData.t),
      orderBy: orderBy?.call(UserAppData.t),
      orderByList: orderByList?.call(UserAppData.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [UserAppData] matching the given query parameters.
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
  Future<UserAppData?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserAppDataTable>? where,
    int? offset,
    _i1.OrderByBuilder<UserAppDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserAppDataTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<UserAppData>(
      where: where?.call(UserAppData.t),
      orderBy: orderBy?.call(UserAppData.t),
      orderByList: orderByList?.call(UserAppData.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [UserAppData] by its [id] or null if no such row exists.
  Future<UserAppData?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<UserAppData>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [UserAppData]s in the list and returns the inserted rows.
  ///
  /// The returned [UserAppData]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<UserAppData>> insert(
    _i1.Session session,
    List<UserAppData> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<UserAppData>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [UserAppData] and returns the inserted row.
  ///
  /// The returned [UserAppData] will have its `id` field set.
  Future<UserAppData> insertRow(
    _i1.Session session,
    UserAppData row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<UserAppData>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [UserAppData]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<UserAppData>> update(
    _i1.Session session,
    List<UserAppData> rows, {
    _i1.ColumnSelections<UserAppDataTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<UserAppData>(
      rows,
      columns: columns?.call(UserAppData.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserAppData]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<UserAppData> updateRow(
    _i1.Session session,
    UserAppData row, {
    _i1.ColumnSelections<UserAppDataTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<UserAppData>(
      row,
      columns: columns?.call(UserAppData.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserAppData] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<UserAppData?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<UserAppDataUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<UserAppData>(
      id,
      columnValues: columnValues(UserAppData.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [UserAppData]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<UserAppData>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<UserAppDataUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<UserAppDataTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserAppDataTable>? orderBy,
    _i1.OrderByListBuilder<UserAppDataTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<UserAppData>(
      columnValues: columnValues(UserAppData.t.updateTable),
      where: where(UserAppData.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserAppData.t),
      orderByList: orderByList?.call(UserAppData.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [UserAppData]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<UserAppData>> delete(
    _i1.Session session,
    List<UserAppData> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<UserAppData>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [UserAppData].
  Future<UserAppData> deleteRow(
    _i1.Session session,
    UserAppData row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<UserAppData>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<UserAppData>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<UserAppDataTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<UserAppData>(
      where: where(UserAppData.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserAppDataTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<UserAppData>(
      where: where?.call(UserAppData.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
