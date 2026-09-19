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

abstract class TrainingChunk
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  TrainingChunk._({
    this.id,
    required this.attemptId,
    required this.sequence,
    required this.digest,
    required this.payloadJson,
  });

  factory TrainingChunk({
    int? id,
    required int attemptId,
    required int sequence,
    required String digest,
    required String payloadJson,
  }) = _TrainingChunkImpl;

  factory TrainingChunk.fromJson(Map<String, dynamic> jsonSerialization) {
    return TrainingChunk(
      id: jsonSerialization['id'] as int?,
      attemptId: jsonSerialization['attemptId'] as int,
      sequence: jsonSerialization['sequence'] as int,
      digest: jsonSerialization['digest'] as String,
      payloadJson: jsonSerialization['payloadJson'] as String,
    );
  }

  static final t = TrainingChunkTable();

  static const db = TrainingChunkRepository._();

  @override
  int? id;

  int attemptId;

  int sequence;

  String digest;

  String payloadJson;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [TrainingChunk]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TrainingChunk copyWith({
    int? id,
    int? attemptId,
    int? sequence,
    String? digest,
    String? payloadJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TrainingChunk',
      if (id != null) 'id': id,
      'attemptId': attemptId,
      'sequence': sequence,
      'digest': digest,
      'payloadJson': payloadJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TrainingChunkInclude include() {
    return TrainingChunkInclude._();
  }

  static TrainingChunkIncludeList includeList({
    _i1.WhereExpressionBuilder<TrainingChunkTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrainingChunkTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrainingChunkTable>? orderByList,
    TrainingChunkInclude? include,
  }) {
    return TrainingChunkIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TrainingChunk.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TrainingChunk.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TrainingChunkImpl extends TrainingChunk {
  _TrainingChunkImpl({
    int? id,
    required int attemptId,
    required int sequence,
    required String digest,
    required String payloadJson,
  }) : super._(
         id: id,
         attemptId: attemptId,
         sequence: sequence,
         digest: digest,
         payloadJson: payloadJson,
       );

  /// Returns a shallow copy of this [TrainingChunk]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TrainingChunk copyWith({
    Object? id = _Undefined,
    int? attemptId,
    int? sequence,
    String? digest,
    String? payloadJson,
  }) {
    return TrainingChunk(
      id: id is int? ? id : this.id,
      attemptId: attemptId ?? this.attemptId,
      sequence: sequence ?? this.sequence,
      digest: digest ?? this.digest,
      payloadJson: payloadJson ?? this.payloadJson,
    );
  }
}

class TrainingChunkUpdateTable extends _i1.UpdateTable<TrainingChunkTable> {
  TrainingChunkUpdateTable(super.table);

  _i1.ColumnValue<int, int> attemptId(int value) => _i1.ColumnValue(
    table.attemptId,
    value,
  );

  _i1.ColumnValue<int, int> sequence(int value) => _i1.ColumnValue(
    table.sequence,
    value,
  );

  _i1.ColumnValue<String, String> digest(String value) => _i1.ColumnValue(
    table.digest,
    value,
  );

  _i1.ColumnValue<String, String> payloadJson(String value) => _i1.ColumnValue(
    table.payloadJson,
    value,
  );
}

class TrainingChunkTable extends _i1.Table<int?> {
  TrainingChunkTable({super.tableRelation})
    : super(tableName: 'training_chunk') {
    updateTable = TrainingChunkUpdateTable(this);
    attemptId = _i1.ColumnInt(
      'attemptId',
      this,
    );
    sequence = _i1.ColumnInt(
      'sequence',
      this,
    );
    digest = _i1.ColumnString(
      'digest',
      this,
    );
    payloadJson = _i1.ColumnString(
      'payloadJson',
      this,
    );
  }

  late final TrainingChunkUpdateTable updateTable;

  late final _i1.ColumnInt attemptId;

  late final _i1.ColumnInt sequence;

  late final _i1.ColumnString digest;

  late final _i1.ColumnString payloadJson;

  @override
  List<_i1.Column> get columns => [
    id,
    attemptId,
    sequence,
    digest,
    payloadJson,
  ];
}

class TrainingChunkInclude extends _i1.IncludeObject {
  TrainingChunkInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => TrainingChunk.t;
}

class TrainingChunkIncludeList extends _i1.IncludeList {
  TrainingChunkIncludeList._({
    _i1.WhereExpressionBuilder<TrainingChunkTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TrainingChunk.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => TrainingChunk.t;
}

class TrainingChunkRepository {
  const TrainingChunkRepository._();

  /// Returns a list of [TrainingChunk]s matching the given query parameters.
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
  Future<List<TrainingChunk>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TrainingChunkTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrainingChunkTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrainingChunkTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TrainingChunk>(
      where: where?.call(TrainingChunk.t),
      orderBy: orderBy?.call(TrainingChunk.t),
      orderByList: orderByList?.call(TrainingChunk.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TrainingChunk] matching the given query parameters.
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
  Future<TrainingChunk?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TrainingChunkTable>? where,
    int? offset,
    _i1.OrderByBuilder<TrainingChunkTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrainingChunkTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TrainingChunk>(
      where: where?.call(TrainingChunk.t),
      orderBy: orderBy?.call(TrainingChunk.t),
      orderByList: orderByList?.call(TrainingChunk.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TrainingChunk] by its [id] or null if no such row exists.
  Future<TrainingChunk?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TrainingChunk>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TrainingChunk]s in the list and returns the inserted rows.
  ///
  /// The returned [TrainingChunk]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<TrainingChunk>> insert(
    _i1.DatabaseSession session,
    List<TrainingChunk> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<TrainingChunk>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [TrainingChunk] and returns the inserted row.
  ///
  /// The returned [TrainingChunk] will have its `id` field set.
  Future<TrainingChunk> insertRow(
    _i1.DatabaseSession session,
    TrainingChunk row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TrainingChunk>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TrainingChunk]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TrainingChunk>> update(
    _i1.DatabaseSession session,
    List<TrainingChunk> rows, {
    _i1.ColumnSelections<TrainingChunkTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TrainingChunk>(
      rows,
      columns: columns?.call(TrainingChunk.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TrainingChunk]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TrainingChunk> updateRow(
    _i1.DatabaseSession session,
    TrainingChunk row, {
    _i1.ColumnSelections<TrainingChunkTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TrainingChunk>(
      row,
      columns: columns?.call(TrainingChunk.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TrainingChunk] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TrainingChunk?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<TrainingChunkUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<TrainingChunk>(
      id,
      columnValues: columnValues(TrainingChunk.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TrainingChunk]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<TrainingChunk>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<TrainingChunkUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TrainingChunkTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrainingChunkTable>? orderBy,
    _i1.OrderByListBuilder<TrainingChunkTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<TrainingChunk>(
      columnValues: columnValues(TrainingChunk.t.updateTable),
      where: where(TrainingChunk.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TrainingChunk.t),
      orderByList: orderByList?.call(TrainingChunk.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [TrainingChunk]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TrainingChunk>> delete(
    _i1.DatabaseSession session,
    List<TrainingChunk> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TrainingChunk>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TrainingChunk].
  Future<TrainingChunk> deleteRow(
    _i1.DatabaseSession session,
    TrainingChunk row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TrainingChunk>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TrainingChunk>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TrainingChunkTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TrainingChunk>(
      where: where(TrainingChunk.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TrainingChunkTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TrainingChunk>(
      where: where?.call(TrainingChunk.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TrainingChunk] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TrainingChunkTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TrainingChunk>(
      where: where(TrainingChunk.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
