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

abstract class LearnerProfile
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  LearnerProfile._({
    this.id,
    required this.userId,
    required this.displayName,
    required this.leaderboardVisible,
  });

  factory LearnerProfile({
    int? id,
    required String userId,
    required String displayName,
    required bool leaderboardVisible,
  }) = _LearnerProfileImpl;

  factory LearnerProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return LearnerProfile(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      displayName: jsonSerialization['displayName'] as String,
      leaderboardVisible: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['leaderboardVisible'],
      ),
    );
  }

  static final t = LearnerProfileTable();

  static const db = LearnerProfileRepository._();

  @override
  int? id;

  String userId;

  String displayName;

  bool leaderboardVisible;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [LearnerProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LearnerProfile copyWith({
    int? id,
    String? userId,
    String? displayName,
    bool? leaderboardVisible,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LearnerProfile',
      if (id != null) 'id': id,
      'userId': userId,
      'displayName': displayName,
      'leaderboardVisible': leaderboardVisible,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LearnerProfile',
      if (id != null) 'id': id,
      'userId': userId,
      'displayName': displayName,
      'leaderboardVisible': leaderboardVisible,
    };
  }

  static LearnerProfileInclude include() {
    return LearnerProfileInclude._();
  }

  static LearnerProfileIncludeList includeList({
    _i1.WhereExpressionBuilder<LearnerProfileTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LearnerProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LearnerProfileTable>? orderByList,
    LearnerProfileInclude? include,
  }) {
    return LearnerProfileIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LearnerProfile.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(LearnerProfile.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LearnerProfileImpl extends LearnerProfile {
  _LearnerProfileImpl({
    int? id,
    required String userId,
    required String displayName,
    required bool leaderboardVisible,
  }) : super._(
         id: id,
         userId: userId,
         displayName: displayName,
         leaderboardVisible: leaderboardVisible,
       );

  /// Returns a shallow copy of this [LearnerProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LearnerProfile copyWith({
    Object? id = _Undefined,
    String? userId,
    String? displayName,
    bool? leaderboardVisible,
  }) {
    return LearnerProfile(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      leaderboardVisible: leaderboardVisible ?? this.leaderboardVisible,
    );
  }
}

class LearnerProfileUpdateTable extends _i1.UpdateTable<LearnerProfileTable> {
  LearnerProfileUpdateTable(super.table);

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> displayName(String value) => _i1.ColumnValue(
    table.displayName,
    value,
  );

  _i1.ColumnValue<bool, bool> leaderboardVisible(bool value) => _i1.ColumnValue(
    table.leaderboardVisible,
    value,
  );
}

class LearnerProfileTable extends _i1.Table<int?> {
  LearnerProfileTable({super.tableRelation})
    : super(tableName: 'learner_profile') {
    updateTable = LearnerProfileUpdateTable(this);
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    displayName = _i1.ColumnString(
      'displayName',
      this,
    );
    leaderboardVisible = _i1.ColumnBool(
      'leaderboardVisible',
      this,
    );
  }

  late final LearnerProfileUpdateTable updateTable;

  late final _i1.ColumnString userId;

  late final _i1.ColumnString displayName;

  late final _i1.ColumnBool leaderboardVisible;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    displayName,
    leaderboardVisible,
  ];
}

class LearnerProfileInclude extends _i1.IncludeObject {
  LearnerProfileInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => LearnerProfile.t;
}

class LearnerProfileIncludeList extends _i1.IncludeList {
  LearnerProfileIncludeList._({
    _i1.WhereExpressionBuilder<LearnerProfileTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LearnerProfile.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => LearnerProfile.t;
}

class LearnerProfileRepository {
  const LearnerProfileRepository._();

  /// Returns a list of [LearnerProfile]s matching the given query parameters.
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
  Future<List<LearnerProfile>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LearnerProfileTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LearnerProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LearnerProfileTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LearnerProfile>(
      where: where?.call(LearnerProfile.t),
      orderBy: orderBy?.call(LearnerProfile.t),
      orderByList: orderByList?.call(LearnerProfile.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LearnerProfile] matching the given query parameters.
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
  Future<LearnerProfile?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LearnerProfileTable>? where,
    int? offset,
    _i1.OrderByBuilder<LearnerProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<LearnerProfileTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LearnerProfile>(
      where: where?.call(LearnerProfile.t),
      orderBy: orderBy?.call(LearnerProfile.t),
      orderByList: orderByList?.call(LearnerProfile.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LearnerProfile] by its [id] or null if no such row exists.
  Future<LearnerProfile?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LearnerProfile>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LearnerProfile]s in the list and returns the inserted rows.
  ///
  /// The returned [LearnerProfile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<LearnerProfile>> insert(
    _i1.DatabaseSession session,
    List<LearnerProfile> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<LearnerProfile>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [LearnerProfile] and returns the inserted row.
  ///
  /// The returned [LearnerProfile] will have its `id` field set.
  Future<LearnerProfile> insertRow(
    _i1.DatabaseSession session,
    LearnerProfile row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<LearnerProfile>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [LearnerProfile]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<LearnerProfile>> update(
    _i1.DatabaseSession session,
    List<LearnerProfile> rows, {
    _i1.ColumnSelections<LearnerProfileTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<LearnerProfile>(
      rows,
      columns: columns?.call(LearnerProfile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LearnerProfile]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LearnerProfile> updateRow(
    _i1.DatabaseSession session,
    LearnerProfile row, {
    _i1.ColumnSelections<LearnerProfileTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<LearnerProfile>(
      row,
      columns: columns?.call(LearnerProfile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LearnerProfile] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LearnerProfile?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<LearnerProfileUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<LearnerProfile>(
      id,
      columnValues: columnValues(LearnerProfile.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LearnerProfile]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<LearnerProfile>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<LearnerProfileUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<LearnerProfileTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<LearnerProfileTable>? orderBy,
    _i1.OrderByListBuilder<LearnerProfileTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<LearnerProfile>(
      columnValues: columnValues(LearnerProfile.t.updateTable),
      where: where(LearnerProfile.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LearnerProfile.t),
      orderByList: orderByList?.call(LearnerProfile.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [LearnerProfile]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<LearnerProfile>> delete(
    _i1.DatabaseSession session,
    List<LearnerProfile> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<LearnerProfile>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [LearnerProfile].
  Future<LearnerProfile> deleteRow(
    _i1.DatabaseSession session,
    LearnerProfile row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LearnerProfile>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<LearnerProfile>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<LearnerProfileTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<LearnerProfile>(
      where: where(LearnerProfile.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<LearnerProfileTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<LearnerProfile>(
      where: where?.call(LearnerProfile.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LearnerProfile] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<LearnerProfileTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LearnerProfile>(
      where: where(LearnerProfile.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
