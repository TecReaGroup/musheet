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

abstract class Application
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Application._({
    this.id,
    required this.appId,
    required this.name,
    this.description,
    this.iconPath,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Application({
    int? id,
    required String appId,
    required String name,
    String? description,
    String? iconPath,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ApplicationImpl;

  factory Application.fromJson(Map<String, dynamic> jsonSerialization) {
    return Application(
      id: jsonSerialization['id'] as int?,
      appId: jsonSerialization['appId'] as String,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      iconPath: jsonSerialization['iconPath'] as String?,
      isActive: jsonSerialization['isActive'] as bool,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = ApplicationTable();

  static const db = ApplicationRepository._();

  @override
  int? id;

  String appId;

  String name;

  String? description;

  String? iconPath;

  bool isActive;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Application]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Application copyWith({
    int? id,
    String? appId,
    String? name,
    String? description,
    String? iconPath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Application',
      if (id != null) 'id': id,
      'appId': appId,
      'name': name,
      if (description != null) 'description': description,
      if (iconPath != null) 'iconPath': iconPath,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Application',
      if (id != null) 'id': id,
      'appId': appId,
      'name': name,
      if (description != null) 'description': description,
      if (iconPath != null) 'iconPath': iconPath,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static ApplicationInclude include() {
    return ApplicationInclude._();
  }

  static ApplicationIncludeList includeList({
    _i1.WhereExpressionBuilder<ApplicationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ApplicationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ApplicationTable>? orderByList,
    ApplicationInclude? include,
  }) {
    return ApplicationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Application.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Application.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ApplicationImpl extends Application {
  _ApplicationImpl({
    int? id,
    required String appId,
    required String name,
    String? description,
    String? iconPath,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         appId: appId,
         name: name,
         description: description,
         iconPath: iconPath,
         isActive: isActive,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Application]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Application copyWith({
    Object? id = _Undefined,
    String? appId,
    String? name,
    Object? description = _Undefined,
    Object? iconPath = _Undefined,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Application(
      id: id is int? ? id : this.id,
      appId: appId ?? this.appId,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      iconPath: iconPath is String? ? iconPath : this.iconPath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ApplicationUpdateTable extends _i1.UpdateTable<ApplicationTable> {
  ApplicationUpdateTable(super.table);

  _i1.ColumnValue<String, String> appId(String value) => _i1.ColumnValue(
    table.appId,
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

  _i1.ColumnValue<String, String> iconPath(String? value) => _i1.ColumnValue(
    table.iconPath,
    value,
  );

  _i1.ColumnValue<bool, bool> isActive(bool value) => _i1.ColumnValue(
    table.isActive,
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

class ApplicationTable extends _i1.Table<int?> {
  ApplicationTable({super.tableRelation}) : super(tableName: 'applications') {
    updateTable = ApplicationUpdateTable(this);
    appId = _i1.ColumnString(
      'appId',
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
    iconPath = _i1.ColumnString(
      'iconPath',
      this,
    );
    isActive = _i1.ColumnBool(
      'isActive',
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

  late final ApplicationUpdateTable updateTable;

  late final _i1.ColumnString appId;

  late final _i1.ColumnString name;

  late final _i1.ColumnString description;

  late final _i1.ColumnString iconPath;

  late final _i1.ColumnBool isActive;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    appId,
    name,
    description,
    iconPath,
    isActive,
    createdAt,
    updatedAt,
  ];
}

class ApplicationInclude extends _i1.IncludeObject {
  ApplicationInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Application.t;
}

class ApplicationIncludeList extends _i1.IncludeList {
  ApplicationIncludeList._({
    _i1.WhereExpressionBuilder<ApplicationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Application.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Application.t;
}

class ApplicationRepository {
  const ApplicationRepository._();

  /// Returns a list of [Application]s matching the given query parameters.
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
  Future<List<Application>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ApplicationTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ApplicationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ApplicationTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Application>(
      where: where?.call(Application.t),
      orderBy: orderBy?.call(Application.t),
      orderByList: orderByList?.call(Application.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Application] matching the given query parameters.
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
  Future<Application?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ApplicationTable>? where,
    int? offset,
    _i1.OrderByBuilder<ApplicationTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ApplicationTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Application>(
      where: where?.call(Application.t),
      orderBy: orderBy?.call(Application.t),
      orderByList: orderByList?.call(Application.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Application] by its [id] or null if no such row exists.
  Future<Application?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Application>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Application]s in the list and returns the inserted rows.
  ///
  /// The returned [Application]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Application>> insert(
    _i1.Session session,
    List<Application> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Application>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Application] and returns the inserted row.
  ///
  /// The returned [Application] will have its `id` field set.
  Future<Application> insertRow(
    _i1.Session session,
    Application row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Application>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Application]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Application>> update(
    _i1.Session session,
    List<Application> rows, {
    _i1.ColumnSelections<ApplicationTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Application>(
      rows,
      columns: columns?.call(Application.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Application]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Application> updateRow(
    _i1.Session session,
    Application row, {
    _i1.ColumnSelections<ApplicationTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Application>(
      row,
      columns: columns?.call(Application.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Application] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Application?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<ApplicationUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Application>(
      id,
      columnValues: columnValues(Application.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Application]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Application>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<ApplicationUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ApplicationTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ApplicationTable>? orderBy,
    _i1.OrderByListBuilder<ApplicationTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Application>(
      columnValues: columnValues(Application.t.updateTable),
      where: where(Application.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Application.t),
      orderByList: orderByList?.call(Application.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Application]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Application>> delete(
    _i1.Session session,
    List<Application> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Application>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Application].
  Future<Application> deleteRow(
    _i1.Session session,
    Application row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Application>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Application>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ApplicationTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Application>(
      where: where(Application.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ApplicationTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Application>(
      where: where?.call(Application.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
