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

abstract class PracticeRepetition
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  PracticeRepetition._({
    this.id,
    required this.assignmentId,
    required this.attemptId,
  });

  factory PracticeRepetition({
    int? id,
    required int assignmentId,
    required int attemptId,
  }) = _PracticeRepetitionImpl;

  factory PracticeRepetition.fromJson(Map<String, dynamic> jsonSerialization) {
    return PracticeRepetition(
      id: jsonSerialization['id'] as int?,
      assignmentId: jsonSerialization['assignmentId'] as int,
      attemptId: jsonSerialization['attemptId'] as int,
    );
  }

  static final t = PracticeRepetitionTable();

  static const db = PracticeRepetitionRepository._();

  @override
  int? id;

  int assignmentId;

  int attemptId;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [PracticeRepetition]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PracticeRepetition copyWith({
    int? id,
    int? assignmentId,
    int? attemptId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PracticeRepetition',
      if (id != null) 'id': id,
      'assignmentId': assignmentId,
      'attemptId': attemptId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PracticeRepetitionInclude include() {
    return PracticeRepetitionInclude._();
  }

  static PracticeRepetitionIncludeList includeList({
    _i1.WhereExpressionBuilder<PracticeRepetitionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PracticeRepetitionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PracticeRepetitionTable>? orderByList,
    PracticeRepetitionInclude? include,
  }) {
    return PracticeRepetitionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PracticeRepetition.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(PracticeRepetition.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PracticeRepetitionImpl extends PracticeRepetition {
  _PracticeRepetitionImpl({
    int? id,
    required int assignmentId,
    required int attemptId,
  }) : super._(
         id: id,
         assignmentId: assignmentId,
         attemptId: attemptId,
       );

  /// Returns a shallow copy of this [PracticeRepetition]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PracticeRepetition copyWith({
    Object? id = _Undefined,
    int? assignmentId,
    int? attemptId,
  }) {
    return PracticeRepetition(
      id: id is int? ? id : this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      attemptId: attemptId ?? this.attemptId,
    );
  }
}

class PracticeRepetitionUpdateTable
    extends _i1.UpdateTable<PracticeRepetitionTable> {
  PracticeRepetitionUpdateTable(super.table);

  _i1.ColumnValue<int, int> assignmentId(int value) => _i1.ColumnValue(
    table.assignmentId,
    value,
  );

  _i1.ColumnValue<int, int> attemptId(int value) => _i1.ColumnValue(
    table.attemptId,
    value,
  );
}

class PracticeRepetitionTable extends _i1.Table<int?> {
  PracticeRepetitionTable({super.tableRelation})
    : super(tableName: 'practice_repetition') {
    updateTable = PracticeRepetitionUpdateTable(this);
    assignmentId = _i1.ColumnInt(
      'assignmentId',
      this,
    );
    attemptId = _i1.ColumnInt(
      'attemptId',
      this,
    );
  }

  late final PracticeRepetitionUpdateTable updateTable;

  late final _i1.ColumnInt assignmentId;

  late final _i1.ColumnInt attemptId;

  @override
  List<_i1.Column> get columns => [
    id,
    assignmentId,
    attemptId,
  ];
}

class PracticeRepetitionInclude extends _i1.IncludeObject {
  PracticeRepetitionInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => PracticeRepetition.t;
}

class PracticeRepetitionIncludeList extends _i1.IncludeList {
  PracticeRepetitionIncludeList._({
    _i1.WhereExpressionBuilder<PracticeRepetitionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PracticeRepetition.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => PracticeRepetition.t;
}

class PracticeRepetitionRepository {
  const PracticeRepetitionRepository._();

  /// Returns a list of [PracticeRepetition]s matching the given query parameters.
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
  Future<List<PracticeRepetition>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PracticeRepetitionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PracticeRepetitionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PracticeRepetitionTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PracticeRepetition>(
      where: where?.call(PracticeRepetition.t),
      orderBy: orderBy?.call(PracticeRepetition.t),
      orderByList: orderByList?.call(PracticeRepetition.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PracticeRepetition] matching the given query parameters.
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
  Future<PracticeRepetition?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PracticeRepetitionTable>? where,
    int? offset,
    _i1.OrderByBuilder<PracticeRepetitionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PracticeRepetitionTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PracticeRepetition>(
      where: where?.call(PracticeRepetition.t),
      orderBy: orderBy?.call(PracticeRepetition.t),
      orderByList: orderByList?.call(PracticeRepetition.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PracticeRepetition] by its [id] or null if no such row exists.
  Future<PracticeRepetition?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PracticeRepetition>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PracticeRepetition]s in the list and returns the inserted rows.
  ///
  /// The returned [PracticeRepetition]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<PracticeRepetition>> insert(
    _i1.DatabaseSession session,
    List<PracticeRepetition> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<PracticeRepetition>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [PracticeRepetition] and returns the inserted row.
  ///
  /// The returned [PracticeRepetition] will have its `id` field set.
  Future<PracticeRepetition> insertRow(
    _i1.DatabaseSession session,
    PracticeRepetition row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<PracticeRepetition>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [PracticeRepetition]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<PracticeRepetition>> update(
    _i1.DatabaseSession session,
    List<PracticeRepetition> rows, {
    _i1.ColumnSelections<PracticeRepetitionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<PracticeRepetition>(
      rows,
      columns: columns?.call(PracticeRepetition.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PracticeRepetition]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PracticeRepetition> updateRow(
    _i1.DatabaseSession session,
    PracticeRepetition row, {
    _i1.ColumnSelections<PracticeRepetitionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<PracticeRepetition>(
      row,
      columns: columns?.call(PracticeRepetition.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PracticeRepetition] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PracticeRepetition?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<PracticeRepetitionUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<PracticeRepetition>(
      id,
      columnValues: columnValues(PracticeRepetition.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PracticeRepetition]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<PracticeRepetition>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<PracticeRepetitionUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<PracticeRepetitionTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PracticeRepetitionTable>? orderBy,
    _i1.OrderByListBuilder<PracticeRepetitionTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<PracticeRepetition>(
      columnValues: columnValues(PracticeRepetition.t.updateTable),
      where: where(PracticeRepetition.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PracticeRepetition.t),
      orderByList: orderByList?.call(PracticeRepetition.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [PracticeRepetition]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<PracticeRepetition>> delete(
    _i1.DatabaseSession session,
    List<PracticeRepetition> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<PracticeRepetition>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [PracticeRepetition].
  Future<PracticeRepetition> deleteRow(
    _i1.DatabaseSession session,
    PracticeRepetition row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PracticeRepetition>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<PracticeRepetition>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PracticeRepetitionTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<PracticeRepetition>(
      where: where(PracticeRepetition.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PracticeRepetitionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<PracticeRepetition>(
      where: where?.call(PracticeRepetition.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PracticeRepetition] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PracticeRepetitionTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PracticeRepetition>(
      where: where(PracticeRepetition.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
