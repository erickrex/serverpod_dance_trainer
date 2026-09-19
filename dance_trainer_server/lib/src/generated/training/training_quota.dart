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

abstract class TrainingQuota
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  TrainingQuota._({
    this.id,
    required this.userId,
    required this.windowStart,
    required this.requests,
  });

  factory TrainingQuota({
    int? id,
    required String userId,
    required DateTime windowStart,
    required int requests,
  }) = _TrainingQuotaImpl;

  factory TrainingQuota.fromJson(Map<String, dynamic> jsonSerialization) {
    return TrainingQuota(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      windowStart: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['windowStart'],
      ),
      requests: jsonSerialization['requests'] as int,
    );
  }

  static final t = TrainingQuotaTable();

  static const db = TrainingQuotaRepository._();

  @override
  int? id;

  String userId;

  DateTime windowStart;

  int requests;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [TrainingQuota]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TrainingQuota copyWith({
    int? id,
    String? userId,
    DateTime? windowStart,
    int? requests,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TrainingQuota',
      if (id != null) 'id': id,
      'userId': userId,
      'windowStart': windowStart.toJson(),
      'requests': requests,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TrainingQuotaInclude include() {
    return TrainingQuotaInclude._();
  }

  static TrainingQuotaIncludeList includeList({
    _i1.WhereExpressionBuilder<TrainingQuotaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrainingQuotaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrainingQuotaTable>? orderByList,
    TrainingQuotaInclude? include,
  }) {
    return TrainingQuotaIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TrainingQuota.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TrainingQuota.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TrainingQuotaImpl extends TrainingQuota {
  _TrainingQuotaImpl({
    int? id,
    required String userId,
    required DateTime windowStart,
    required int requests,
  }) : super._(
         id: id,
         userId: userId,
         windowStart: windowStart,
         requests: requests,
       );

  /// Returns a shallow copy of this [TrainingQuota]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TrainingQuota copyWith({
    Object? id = _Undefined,
    String? userId,
    DateTime? windowStart,
    int? requests,
  }) {
    return TrainingQuota(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      windowStart: windowStart ?? this.windowStart,
      requests: requests ?? this.requests,
    );
  }
}

class TrainingQuotaUpdateTable extends _i1.UpdateTable<TrainingQuotaTable> {
  TrainingQuotaUpdateTable(super.table);

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> windowStart(DateTime value) =>
      _i1.ColumnValue(
        table.windowStart,
        value,
      );

  _i1.ColumnValue<int, int> requests(int value) => _i1.ColumnValue(
    table.requests,
    value,
  );
}

class TrainingQuotaTable extends _i1.Table<int?> {
  TrainingQuotaTable({super.tableRelation})
    : super(tableName: 'training_quota') {
    updateTable = TrainingQuotaUpdateTable(this);
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    windowStart = _i1.ColumnDateTime(
      'windowStart',
      this,
    );
    requests = _i1.ColumnInt(
      'requests',
      this,
    );
  }

  late final TrainingQuotaUpdateTable updateTable;

  late final _i1.ColumnString userId;

  late final _i1.ColumnDateTime windowStart;

  late final _i1.ColumnInt requests;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    windowStart,
    requests,
  ];
}

class TrainingQuotaInclude extends _i1.IncludeObject {
  TrainingQuotaInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => TrainingQuota.t;
}

class TrainingQuotaIncludeList extends _i1.IncludeList {
  TrainingQuotaIncludeList._({
    _i1.WhereExpressionBuilder<TrainingQuotaTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TrainingQuota.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => TrainingQuota.t;
}

class TrainingQuotaRepository {
  const TrainingQuotaRepository._();

  /// Returns a list of [TrainingQuota]s matching the given query parameters.
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
  Future<List<TrainingQuota>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TrainingQuotaTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrainingQuotaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrainingQuotaTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TrainingQuota>(
      where: where?.call(TrainingQuota.t),
      orderBy: orderBy?.call(TrainingQuota.t),
      orderByList: orderByList?.call(TrainingQuota.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TrainingQuota] matching the given query parameters.
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
  Future<TrainingQuota?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TrainingQuotaTable>? where,
    int? offset,
    _i1.OrderByBuilder<TrainingQuotaTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrainingQuotaTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TrainingQuota>(
      where: where?.call(TrainingQuota.t),
      orderBy: orderBy?.call(TrainingQuota.t),
      orderByList: orderByList?.call(TrainingQuota.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TrainingQuota] by its [id] or null if no such row exists.
  Future<TrainingQuota?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TrainingQuota>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TrainingQuota]s in the list and returns the inserted rows.
  ///
  /// The returned [TrainingQuota]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<TrainingQuota>> insert(
    _i1.DatabaseSession session,
    List<TrainingQuota> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<TrainingQuota>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [TrainingQuota] and returns the inserted row.
  ///
  /// The returned [TrainingQuota] will have its `id` field set.
  Future<TrainingQuota> insertRow(
    _i1.DatabaseSession session,
    TrainingQuota row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TrainingQuota>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TrainingQuota]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TrainingQuota>> update(
    _i1.DatabaseSession session,
    List<TrainingQuota> rows, {
    _i1.ColumnSelections<TrainingQuotaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TrainingQuota>(
      rows,
      columns: columns?.call(TrainingQuota.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TrainingQuota]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TrainingQuota> updateRow(
    _i1.DatabaseSession session,
    TrainingQuota row, {
    _i1.ColumnSelections<TrainingQuotaTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TrainingQuota>(
      row,
      columns: columns?.call(TrainingQuota.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TrainingQuota] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TrainingQuota?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<TrainingQuotaUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<TrainingQuota>(
      id,
      columnValues: columnValues(TrainingQuota.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TrainingQuota]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<TrainingQuota>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<TrainingQuotaUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TrainingQuotaTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrainingQuotaTable>? orderBy,
    _i1.OrderByListBuilder<TrainingQuotaTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<TrainingQuota>(
      columnValues: columnValues(TrainingQuota.t.updateTable),
      where: where(TrainingQuota.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TrainingQuota.t),
      orderByList: orderByList?.call(TrainingQuota.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [TrainingQuota]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TrainingQuota>> delete(
    _i1.DatabaseSession session,
    List<TrainingQuota> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TrainingQuota>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TrainingQuota].
  Future<TrainingQuota> deleteRow(
    _i1.DatabaseSession session,
    TrainingQuota row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TrainingQuota>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TrainingQuota>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TrainingQuotaTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TrainingQuota>(
      where: where(TrainingQuota.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TrainingQuotaTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TrainingQuota>(
      where: where?.call(TrainingQuota.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TrainingQuota] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TrainingQuotaTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TrainingQuota>(
      where: where(TrainingQuota.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
