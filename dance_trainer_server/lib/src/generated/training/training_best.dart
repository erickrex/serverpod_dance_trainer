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

abstract class TrainingBest
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  TrainingBest._({
    this.id,
    required this.userId,
    required this.boardKey,
    required this.attemptId,
    required this.score,
    required this.achievedAt,
  });

  factory TrainingBest({
    int? id,
    required String userId,
    required String boardKey,
    required int attemptId,
    required int score,
    required DateTime achievedAt,
  }) = _TrainingBestImpl;

  factory TrainingBest.fromJson(Map<String, dynamic> jsonSerialization) {
    return TrainingBest(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      boardKey: jsonSerialization['boardKey'] as String,
      attemptId: jsonSerialization['attemptId'] as int,
      score: jsonSerialization['score'] as int,
      achievedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['achievedAt'],
      ),
    );
  }

  static final t = TrainingBestTable();

  static const db = TrainingBestRepository._();

  @override
  int? id;

  String userId;

  String boardKey;

  int attemptId;

  int score;

  DateTime achievedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [TrainingBest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TrainingBest copyWith({
    int? id,
    String? userId,
    String? boardKey,
    int? attemptId,
    int? score,
    DateTime? achievedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TrainingBest',
      if (id != null) 'id': id,
      'userId': userId,
      'boardKey': boardKey,
      'attemptId': attemptId,
      'score': score,
      'achievedAt': achievedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TrainingBestInclude include() {
    return TrainingBestInclude._();
  }

  static TrainingBestIncludeList includeList({
    _i1.WhereExpressionBuilder<TrainingBestTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrainingBestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrainingBestTable>? orderByList,
    TrainingBestInclude? include,
  }) {
    return TrainingBestIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TrainingBest.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TrainingBest.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TrainingBestImpl extends TrainingBest {
  _TrainingBestImpl({
    int? id,
    required String userId,
    required String boardKey,
    required int attemptId,
    required int score,
    required DateTime achievedAt,
  }) : super._(
         id: id,
         userId: userId,
         boardKey: boardKey,
         attemptId: attemptId,
         score: score,
         achievedAt: achievedAt,
       );

  /// Returns a shallow copy of this [TrainingBest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TrainingBest copyWith({
    Object? id = _Undefined,
    String? userId,
    String? boardKey,
    int? attemptId,
    int? score,
    DateTime? achievedAt,
  }) {
    return TrainingBest(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      boardKey: boardKey ?? this.boardKey,
      attemptId: attemptId ?? this.attemptId,
      score: score ?? this.score,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }
}

class TrainingBestUpdateTable extends _i1.UpdateTable<TrainingBestTable> {
  TrainingBestUpdateTable(super.table);

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> boardKey(String value) => _i1.ColumnValue(
    table.boardKey,
    value,
  );

  _i1.ColumnValue<int, int> attemptId(int value) => _i1.ColumnValue(
    table.attemptId,
    value,
  );

  _i1.ColumnValue<int, int> score(int value) => _i1.ColumnValue(
    table.score,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> achievedAt(DateTime value) =>
      _i1.ColumnValue(
        table.achievedAt,
        value,
      );
}

class TrainingBestTable extends _i1.Table<int?> {
  TrainingBestTable({super.tableRelation}) : super(tableName: 'training_best') {
    updateTable = TrainingBestUpdateTable(this);
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    boardKey = _i1.ColumnString(
      'boardKey',
      this,
    );
    attemptId = _i1.ColumnInt(
      'attemptId',
      this,
    );
    score = _i1.ColumnInt(
      'score',
      this,
    );
    achievedAt = _i1.ColumnDateTime(
      'achievedAt',
      this,
    );
  }

  late final TrainingBestUpdateTable updateTable;

  late final _i1.ColumnString userId;

  late final _i1.ColumnString boardKey;

  late final _i1.ColumnInt attemptId;

  late final _i1.ColumnInt score;

  late final _i1.ColumnDateTime achievedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    boardKey,
    attemptId,
    score,
    achievedAt,
  ];
}

class TrainingBestInclude extends _i1.IncludeObject {
  TrainingBestInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => TrainingBest.t;
}

class TrainingBestIncludeList extends _i1.IncludeList {
  TrainingBestIncludeList._({
    _i1.WhereExpressionBuilder<TrainingBestTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TrainingBest.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => TrainingBest.t;
}

class TrainingBestRepository {
  const TrainingBestRepository._();

  /// Returns a list of [TrainingBest]s matching the given query parameters.
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
  Future<List<TrainingBest>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TrainingBestTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrainingBestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrainingBestTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TrainingBest>(
      where: where?.call(TrainingBest.t),
      orderBy: orderBy?.call(TrainingBest.t),
      orderByList: orderByList?.call(TrainingBest.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TrainingBest] matching the given query parameters.
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
  Future<TrainingBest?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TrainingBestTable>? where,
    int? offset,
    _i1.OrderByBuilder<TrainingBestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrainingBestTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TrainingBest>(
      where: where?.call(TrainingBest.t),
      orderBy: orderBy?.call(TrainingBest.t),
      orderByList: orderByList?.call(TrainingBest.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TrainingBest] by its [id] or null if no such row exists.
  Future<TrainingBest?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TrainingBest>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TrainingBest]s in the list and returns the inserted rows.
  ///
  /// The returned [TrainingBest]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<TrainingBest>> insert(
    _i1.DatabaseSession session,
    List<TrainingBest> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<TrainingBest>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [TrainingBest] and returns the inserted row.
  ///
  /// The returned [TrainingBest] will have its `id` field set.
  Future<TrainingBest> insertRow(
    _i1.DatabaseSession session,
    TrainingBest row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TrainingBest>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TrainingBest]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TrainingBest>> update(
    _i1.DatabaseSession session,
    List<TrainingBest> rows, {
    _i1.ColumnSelections<TrainingBestTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TrainingBest>(
      rows,
      columns: columns?.call(TrainingBest.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TrainingBest]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TrainingBest> updateRow(
    _i1.DatabaseSession session,
    TrainingBest row, {
    _i1.ColumnSelections<TrainingBestTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TrainingBest>(
      row,
      columns: columns?.call(TrainingBest.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TrainingBest] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TrainingBest?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<TrainingBestUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<TrainingBest>(
      id,
      columnValues: columnValues(TrainingBest.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TrainingBest]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<TrainingBest>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<TrainingBestUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TrainingBestTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrainingBestTable>? orderBy,
    _i1.OrderByListBuilder<TrainingBestTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<TrainingBest>(
      columnValues: columnValues(TrainingBest.t.updateTable),
      where: where(TrainingBest.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TrainingBest.t),
      orderByList: orderByList?.call(TrainingBest.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [TrainingBest]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TrainingBest>> delete(
    _i1.DatabaseSession session,
    List<TrainingBest> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TrainingBest>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TrainingBest].
  Future<TrainingBest> deleteRow(
    _i1.DatabaseSession session,
    TrainingBest row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TrainingBest>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TrainingBest>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TrainingBestTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TrainingBest>(
      where: where(TrainingBest.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TrainingBestTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TrainingBest>(
      where: where?.call(TrainingBest.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TrainingBest] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TrainingBestTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TrainingBest>(
      where: where(TrainingBest.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
