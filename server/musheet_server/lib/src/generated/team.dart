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

abstract class Team implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Team._({
    this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team({
    int? id,
    required String name,
    String? description,
    required String inviteCode,
    required int createdById,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TeamImpl;

  factory Team.fromJson(Map<String, dynamic> jsonSerialization) {
    return Team(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      inviteCode: jsonSerialization['inviteCode'] as String,
      createdById: jsonSerialization['createdById'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = TeamTable();

  static const db = TeamRepository._();

  @override
  int? id;

  String name;

  String? description;

  String inviteCode;

  int createdById;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Team]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Team copyWith({
    int? id,
    String? name,
    String? description,
    String? inviteCode,
    int? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Team',
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'inviteCode': inviteCode,
      'createdById': createdById,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Team',
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'inviteCode': inviteCode,
      'createdById': createdById,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static TeamInclude include() {
    return TeamInclude._();
  }

  static TeamIncludeList includeList({
    _i1.WhereExpressionBuilder<TeamTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TeamTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TeamTable>? orderByList,
    TeamInclude? include,
  }) {
    return TeamIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Team.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Team.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TeamImpl extends Team {
  _TeamImpl({
    int? id,
    required String name,
    String? description,
    required String inviteCode,
    required int createdById,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         name: name,
         description: description,
         inviteCode: inviteCode,
         createdById: createdById,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Team]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Team copyWith({
    Object? id = _Undefined,
    String? name,
    Object? description = _Undefined,
    String? inviteCode,
    int? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      inviteCode: inviteCode ?? this.inviteCode,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TeamUpdateTable extends _i1.UpdateTable<TeamTable> {
  TeamUpdateTable(super.table);

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> description(String? value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<String, String> inviteCode(String value) => _i1.ColumnValue(
    table.inviteCode,
    value,
  );

  _i1.ColumnValue<int, int> createdById(int value) => _i1.ColumnValue(
    table.createdById,
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

class TeamTable extends _i1.Table<int?> {
  TeamTable({super.tableRelation}) : super(tableName: 'teams') {
    updateTable = TeamUpdateTable(this);
    name = _i1.ColumnString(
      'name',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
    );
    inviteCode = _i1.ColumnString(
      'inviteCode',
      this,
    );
    createdById = _i1.ColumnInt(
      'createdById',
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

  late final TeamUpdateTable updateTable;

  late final _i1.ColumnString name;

  late final _i1.ColumnString description;

  late final _i1.ColumnString inviteCode;

  late final _i1.ColumnInt createdById;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    name,
    description,
    inviteCode,
    createdById,
    createdAt,
    updatedAt,
  ];
}

class TeamInclude extends _i1.IncludeObject {
  TeamInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Team.t;
}

class TeamIncludeList extends _i1.IncludeList {
  TeamIncludeList._({
    _i1.WhereExpressionBuilder<TeamTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Team.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Team.t;
}

class TeamRepository {
  const TeamRepository._();

  /// Returns a list of [Team]s matching the given query parameters.
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
  Future<List<Team>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TeamTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TeamTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TeamTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Team>(
      where: where?.call(Team.t),
      orderBy: orderBy?.call(Team.t),
      orderByList: orderByList?.call(Team.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Team] matching the given query parameters.
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
  Future<Team?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TeamTable>? where,
    int? offset,
    _i1.OrderByBuilder<TeamTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TeamTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Team>(
      where: where?.call(Team.t),
      orderBy: orderBy?.call(Team.t),
      orderByList: orderByList?.call(Team.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Team] by its [id] or null if no such row exists.
  Future<Team?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Team>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Team]s in the list and returns the inserted rows.
  ///
  /// The returned [Team]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Team>> insert(
    _i1.Session session,
    List<Team> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Team>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Team] and returns the inserted row.
  ///
  /// The returned [Team] will have its `id` field set.
  Future<Team> insertRow(
    _i1.Session session,
    Team row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Team>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Team]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Team>> update(
    _i1.Session session,
    List<Team> rows, {
    _i1.ColumnSelections<TeamTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Team>(
      rows,
      columns: columns?.call(Team.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Team]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Team> updateRow(
    _i1.Session session,
    Team row, {
    _i1.ColumnSelections<TeamTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Team>(
      row,
      columns: columns?.call(Team.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Team] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Team?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<TeamUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Team>(
      id,
      columnValues: columnValues(Team.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Team]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Team>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<TeamUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TeamTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TeamTable>? orderBy,
    _i1.OrderByListBuilder<TeamTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Team>(
      columnValues: columnValues(Team.t.updateTable),
      where: where(Team.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Team.t),
      orderByList: orderByList?.call(Team.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Team]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Team>> delete(
    _i1.Session session,
    List<Team> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Team>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Team].
  Future<Team> deleteRow(
    _i1.Session session,
    Team row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Team>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Team>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TeamTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Team>(
      where: where(Team.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TeamTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Team>(
      where: where?.call(Team.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
