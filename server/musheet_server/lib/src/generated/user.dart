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

abstract class User implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  User._({
    this.id,
    required this.username,
    required this.passwordHash,
    this.displayName,
    this.avatarPath,
    this.bio,
    this.preferredInstrument,
    required this.isAdmin,
    required this.isDisabled,
    required this.mustChangePassword,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User({
    int? id,
    required String username,
    required String passwordHash,
    String? displayName,
    String? avatarPath,
    String? bio,
    String? preferredInstrument,
    required bool isAdmin,
    required bool isDisabled,
    required bool mustChangePassword,
    DateTime? lastLoginAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserImpl;

  factory User.fromJson(Map<String, dynamic> jsonSerialization) {
    return User(
      id: jsonSerialization['id'] as int?,
      username: jsonSerialization['username'] as String,
      passwordHash: jsonSerialization['passwordHash'] as String,
      displayName: jsonSerialization['displayName'] as String?,
      avatarPath: jsonSerialization['avatarPath'] as String?,
      bio: jsonSerialization['bio'] as String?,
      preferredInstrument: jsonSerialization['preferredInstrument'] as String?,
      isAdmin: jsonSerialization['isAdmin'] as bool,
      isDisabled: jsonSerialization['isDisabled'] as bool,
      mustChangePassword: jsonSerialization['mustChangePassword'] as bool,
      lastLoginAt: jsonSerialization['lastLoginAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastLoginAt'],
            ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = UserTable();

  static const db = UserRepository._();

  @override
  int? id;

  String username;

  String passwordHash;

  String? displayName;

  String? avatarPath;

  String? bio;

  String? preferredInstrument;

  bool isAdmin;

  bool isDisabled;

  bool mustChangePassword;

  DateTime? lastLoginAt;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [User]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  User copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? displayName,
    String? avatarPath,
    String? bio,
    String? preferredInstrument,
    bool? isAdmin,
    bool? isDisabled,
    bool? mustChangePassword,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'User',
      if (id != null) 'id': id,
      'username': username,
      'passwordHash': passwordHash,
      if (displayName != null) 'displayName': displayName,
      if (avatarPath != null) 'avatarPath': avatarPath,
      if (bio != null) 'bio': bio,
      if (preferredInstrument != null)
        'preferredInstrument': preferredInstrument,
      'isAdmin': isAdmin,
      'isDisabled': isDisabled,
      'mustChangePassword': mustChangePassword,
      if (lastLoginAt != null) 'lastLoginAt': lastLoginAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'User',
      if (id != null) 'id': id,
      'username': username,
      'passwordHash': passwordHash,
      if (displayName != null) 'displayName': displayName,
      if (avatarPath != null) 'avatarPath': avatarPath,
      if (bio != null) 'bio': bio,
      if (preferredInstrument != null)
        'preferredInstrument': preferredInstrument,
      'isAdmin': isAdmin,
      'isDisabled': isDisabled,
      'mustChangePassword': mustChangePassword,
      if (lastLoginAt != null) 'lastLoginAt': lastLoginAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static UserInclude include() {
    return UserInclude._();
  }

  static UserIncludeList includeList({
    _i1.WhereExpressionBuilder<UserTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserTable>? orderByList,
    UserInclude? include,
  }) {
    return UserIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(User.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(User.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserImpl extends User {
  _UserImpl({
    int? id,
    required String username,
    required String passwordHash,
    String? displayName,
    String? avatarPath,
    String? bio,
    String? preferredInstrument,
    required bool isAdmin,
    required bool isDisabled,
    required bool mustChangePassword,
    DateTime? lastLoginAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         username: username,
         passwordHash: passwordHash,
         displayName: displayName,
         avatarPath: avatarPath,
         bio: bio,
         preferredInstrument: preferredInstrument,
         isAdmin: isAdmin,
         isDisabled: isDisabled,
         mustChangePassword: mustChangePassword,
         lastLoginAt: lastLoginAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [User]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  User copyWith({
    Object? id = _Undefined,
    String? username,
    String? passwordHash,
    Object? displayName = _Undefined,
    Object? avatarPath = _Undefined,
    Object? bio = _Undefined,
    Object? preferredInstrument = _Undefined,
    bool? isAdmin,
    bool? isDisabled,
    bool? mustChangePassword,
    Object? lastLoginAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id is int? ? id : this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarPath: avatarPath is String? ? avatarPath : this.avatarPath,
      bio: bio is String? ? bio : this.bio,
      preferredInstrument: preferredInstrument is String?
          ? preferredInstrument
          : this.preferredInstrument,
      isAdmin: isAdmin ?? this.isAdmin,
      isDisabled: isDisabled ?? this.isDisabled,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      lastLoginAt: lastLoginAt is DateTime? ? lastLoginAt : this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserUpdateTable extends _i1.UpdateTable<UserTable> {
  UserUpdateTable(super.table);

  _i1.ColumnValue<String, String> username(String value) => _i1.ColumnValue(
    table.username,
    value,
  );

  _i1.ColumnValue<String, String> passwordHash(String value) => _i1.ColumnValue(
    table.passwordHash,
    value,
  );

  _i1.ColumnValue<String, String> displayName(String? value) => _i1.ColumnValue(
    table.displayName,
    value,
  );

  _i1.ColumnValue<String, String> avatarPath(String? value) => _i1.ColumnValue(
    table.avatarPath,
    value,
  );

  _i1.ColumnValue<String, String> bio(String? value) => _i1.ColumnValue(
    table.bio,
    value,
  );

  _i1.ColumnValue<String, String> preferredInstrument(String? value) =>
      _i1.ColumnValue(
        table.preferredInstrument,
        value,
      );

  _i1.ColumnValue<bool, bool> isAdmin(bool value) => _i1.ColumnValue(
    table.isAdmin,
    value,
  );

  _i1.ColumnValue<bool, bool> isDisabled(bool value) => _i1.ColumnValue(
    table.isDisabled,
    value,
  );

  _i1.ColumnValue<bool, bool> mustChangePassword(bool value) => _i1.ColumnValue(
    table.mustChangePassword,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> lastLoginAt(DateTime? value) =>
      _i1.ColumnValue(
        table.lastLoginAt,
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

class UserTable extends _i1.Table<int?> {
  UserTable({super.tableRelation}) : super(tableName: 'users') {
    updateTable = UserUpdateTable(this);
    username = _i1.ColumnString(
      'username',
      this,
    );
    passwordHash = _i1.ColumnString(
      'passwordHash',
      this,
    );
    displayName = _i1.ColumnString(
      'displayName',
      this,
    );
    avatarPath = _i1.ColumnString(
      'avatarPath',
      this,
    );
    bio = _i1.ColumnString(
      'bio',
      this,
    );
    preferredInstrument = _i1.ColumnString(
      'preferredInstrument',
      this,
    );
    isAdmin = _i1.ColumnBool(
      'isAdmin',
      this,
    );
    isDisabled = _i1.ColumnBool(
      'isDisabled',
      this,
    );
    mustChangePassword = _i1.ColumnBool(
      'mustChangePassword',
      this,
    );
    lastLoginAt = _i1.ColumnDateTime(
      'lastLoginAt',
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

  late final UserUpdateTable updateTable;

  late final _i1.ColumnString username;

  late final _i1.ColumnString passwordHash;

  late final _i1.ColumnString displayName;

  late final _i1.ColumnString avatarPath;

  late final _i1.ColumnString bio;

  late final _i1.ColumnString preferredInstrument;

  late final _i1.ColumnBool isAdmin;

  late final _i1.ColumnBool isDisabled;

  late final _i1.ColumnBool mustChangePassword;

  late final _i1.ColumnDateTime lastLoginAt;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    username,
    passwordHash,
    displayName,
    avatarPath,
    bio,
    preferredInstrument,
    isAdmin,
    isDisabled,
    mustChangePassword,
    lastLoginAt,
    createdAt,
    updatedAt,
  ];
}

class UserInclude extends _i1.IncludeObject {
  UserInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => User.t;
}

class UserIncludeList extends _i1.IncludeList {
  UserIncludeList._({
    _i1.WhereExpressionBuilder<UserTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(User.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => User.t;
}

class UserRepository {
  const UserRepository._();

  /// Returns a list of [User]s matching the given query parameters.
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
  Future<List<User>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<User>(
      where: where?.call(User.t),
      orderBy: orderBy?.call(User.t),
      orderByList: orderByList?.call(User.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [User] matching the given query parameters.
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
  Future<User?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserTable>? where,
    int? offset,
    _i1.OrderByBuilder<UserTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<User>(
      where: where?.call(User.t),
      orderBy: orderBy?.call(User.t),
      orderByList: orderByList?.call(User.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [User] by its [id] or null if no such row exists.
  Future<User?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<User>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [User]s in the list and returns the inserted rows.
  ///
  /// The returned [User]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<User>> insert(
    _i1.Session session,
    List<User> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<User>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [User] and returns the inserted row.
  ///
  /// The returned [User] will have its `id` field set.
  Future<User> insertRow(
    _i1.Session session,
    User row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<User>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [User]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<User>> update(
    _i1.Session session,
    List<User> rows, {
    _i1.ColumnSelections<UserTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<User>(
      rows,
      columns: columns?.call(User.t),
      transaction: transaction,
    );
  }

  /// Updates a single [User]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<User> updateRow(
    _i1.Session session,
    User row, {
    _i1.ColumnSelections<UserTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<User>(
      row,
      columns: columns?.call(User.t),
      transaction: transaction,
    );
  }

  /// Updates a single [User] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<User?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<UserUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<User>(
      id,
      columnValues: columnValues(User.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [User]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<User>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<UserUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<UserTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserTable>? orderBy,
    _i1.OrderByListBuilder<UserTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<User>(
      columnValues: columnValues(User.t.updateTable),
      where: where(User.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(User.t),
      orderByList: orderByList?.call(User.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [User]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<User>> delete(
    _i1.Session session,
    List<User> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<User>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [User].
  Future<User> deleteRow(
    _i1.Session session,
    User row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<User>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<User>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<UserTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<User>(
      where: where(User.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<UserTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<User>(
      where: where?.call(User.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
