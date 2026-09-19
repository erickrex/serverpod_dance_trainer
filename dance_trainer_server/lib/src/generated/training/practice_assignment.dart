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

abstract class PracticeAssignment
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  PracticeAssignment._({
    this.id,
    required this.userId,
    required this.sourceAttemptId,
    required this.routineId,
    required this.contentVersion,
    required this.sectionId,
    required this.completedRepetitions,
    required this.completed,
  });

  factory PracticeAssignment({
    int? id,
    required String userId,
    required int sourceAttemptId,
    required String routineId,
    required String contentVersion,
    required String sectionId,
    required int completedRepetitions,
    required bool completed,
  }) = _PracticeAssignmentImpl;

  factory PracticeAssignment.fromJson(Map<String, dynamic> jsonSerialization) {
    return PracticeAssignment(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      sourceAttemptId: jsonSerialization['sourceAttemptId'] as int,
      routineId: jsonSerialization['routineId'] as String,
      contentVersion: jsonSerialization['contentVersion'] as String,
      sectionId: jsonSerialization['sectionId'] as String,
      completedRepetitions: jsonSerialization['completedRepetitions'] as int,
      completed: _i1.BoolJsonExtension.fromJson(jsonSerialization['completed']),
    );
  }

  static final t = PracticeAssignmentTable();

  static const db = PracticeAssignmentRepository._();

  @override
  int? id;

  String userId;

  int sourceAttemptId;

  String routineId;

  String contentVersion;

  String sectionId;

  int completedRepetitions;

  bool completed;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [PracticeAssignment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PracticeAssignment copyWith({
    int? id,
    String? userId,
    int? sourceAttemptId,
    String? routineId,
    String? contentVersion,
    String? sectionId,
    int? completedRepetitions,
    bool? completed,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PracticeAssignment',
      if (id != null) 'id': id,
      'userId': userId,
      'sourceAttemptId': sourceAttemptId,
      'routineId': routineId,
      'contentVersion': contentVersion,
      'sectionId': sectionId,
      'completedRepetitions': completedRepetitions,
      'completed': completed,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PracticeAssignment',
      if (id != null) 'id': id,
      'userId': userId,
      'sourceAttemptId': sourceAttemptId,
      'routineId': routineId,
      'contentVersion': contentVersion,
      'sectionId': sectionId,
      'completedRepetitions': completedRepetitions,
      'completed': completed,
    };
  }

  static PracticeAssignmentInclude include() {
    return PracticeAssignmentInclude._();
  }

  static PracticeAssignmentIncludeList includeList({
    _i1.WhereExpressionBuilder<PracticeAssignmentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PracticeAssignmentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PracticeAssignmentTable>? orderByList,
    PracticeAssignmentInclude? include,
  }) {
    return PracticeAssignmentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PracticeAssignment.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(PracticeAssignment.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PracticeAssignmentImpl extends PracticeAssignment {
  _PracticeAssignmentImpl({
    int? id,
    required String userId,
    required int sourceAttemptId,
    required String routineId,
    required String contentVersion,
    required String sectionId,
    required int completedRepetitions,
    required bool completed,
  }) : super._(
         id: id,
         userId: userId,
         sourceAttemptId: sourceAttemptId,
         routineId: routineId,
         contentVersion: contentVersion,
         sectionId: sectionId,
         completedRepetitions: completedRepetitions,
         completed: completed,
       );

  /// Returns a shallow copy of this [PracticeAssignment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PracticeAssignment copyWith({
    Object? id = _Undefined,
    String? userId,
    int? sourceAttemptId,
    String? routineId,
    String? contentVersion,
    String? sectionId,
    int? completedRepetitions,
    bool? completed,
  }) {
    return PracticeAssignment(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      sourceAttemptId: sourceAttemptId ?? this.sourceAttemptId,
      routineId: routineId ?? this.routineId,
      contentVersion: contentVersion ?? this.contentVersion,
      sectionId: sectionId ?? this.sectionId,
      completedRepetitions: completedRepetitions ?? this.completedRepetitions,
      completed: completed ?? this.completed,
    );
  }
}

class PracticeAssignmentUpdateTable
    extends _i1.UpdateTable<PracticeAssignmentTable> {
  PracticeAssignmentUpdateTable(super.table);

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<int, int> sourceAttemptId(int value) => _i1.ColumnValue(
    table.sourceAttemptId,
    value,
  );

  _i1.ColumnValue<String, String> routineId(String value) => _i1.ColumnValue(
    table.routineId,
    value,
  );

  _i1.ColumnValue<String, String> contentVersion(String value) =>
      _i1.ColumnValue(
        table.contentVersion,
        value,
      );

  _i1.ColumnValue<String, String> sectionId(String value) => _i1.ColumnValue(
    table.sectionId,
    value,
  );

  _i1.ColumnValue<int, int> completedRepetitions(int value) => _i1.ColumnValue(
    table.completedRepetitions,
    value,
  );

  _i1.ColumnValue<bool, bool> completed(bool value) => _i1.ColumnValue(
    table.completed,
    value,
  );
}

class PracticeAssignmentTable extends _i1.Table<int?> {
  PracticeAssignmentTable({super.tableRelation})
    : super(tableName: 'practice_assignment') {
    updateTable = PracticeAssignmentUpdateTable(this);
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    sourceAttemptId = _i1.ColumnInt(
      'sourceAttemptId',
      this,
    );
    routineId = _i1.ColumnString(
      'routineId',
      this,
    );
    contentVersion = _i1.ColumnString(
      'contentVersion',
      this,
    );
    sectionId = _i1.ColumnString(
      'sectionId',
      this,
    );
    completedRepetitions = _i1.ColumnInt(
      'completedRepetitions',
      this,
    );
    completed = _i1.ColumnBool(
      'completed',
      this,
    );
  }

  late final PracticeAssignmentUpdateTable updateTable;

  late final _i1.ColumnString userId;

  late final _i1.ColumnInt sourceAttemptId;

  late final _i1.ColumnString routineId;

  late final _i1.ColumnString contentVersion;

  late final _i1.ColumnString sectionId;

  late final _i1.ColumnInt completedRepetitions;

  late final _i1.ColumnBool completed;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    sourceAttemptId,
    routineId,
    contentVersion,
    sectionId,
    completedRepetitions,
    completed,
  ];
}

class PracticeAssignmentInclude extends _i1.IncludeObject {
  PracticeAssignmentInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => PracticeAssignment.t;
}

class PracticeAssignmentIncludeList extends _i1.IncludeList {
  PracticeAssignmentIncludeList._({
    _i1.WhereExpressionBuilder<PracticeAssignmentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PracticeAssignment.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => PracticeAssignment.t;
}

class PracticeAssignmentRepository {
  const PracticeAssignmentRepository._();

  /// Returns a list of [PracticeAssignment]s matching the given query parameters.
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
  Future<List<PracticeAssignment>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PracticeAssignmentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PracticeAssignmentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PracticeAssignmentTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PracticeAssignment>(
      where: where?.call(PracticeAssignment.t),
      orderBy: orderBy?.call(PracticeAssignment.t),
      orderByList: orderByList?.call(PracticeAssignment.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PracticeAssignment] matching the given query parameters.
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
  Future<PracticeAssignment?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PracticeAssignmentTable>? where,
    int? offset,
    _i1.OrderByBuilder<PracticeAssignmentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PracticeAssignmentTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PracticeAssignment>(
      where: where?.call(PracticeAssignment.t),
      orderBy: orderBy?.call(PracticeAssignment.t),
      orderByList: orderByList?.call(PracticeAssignment.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PracticeAssignment] by its [id] or null if no such row exists.
  Future<PracticeAssignment?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PracticeAssignment>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PracticeAssignment]s in the list and returns the inserted rows.
  ///
  /// The returned [PracticeAssignment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<PracticeAssignment>> insert(
    _i1.DatabaseSession session,
    List<PracticeAssignment> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<PracticeAssignment>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [PracticeAssignment] and returns the inserted row.
  ///
  /// The returned [PracticeAssignment] will have its `id` field set.
  Future<PracticeAssignment> insertRow(
    _i1.DatabaseSession session,
    PracticeAssignment row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<PracticeAssignment>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [PracticeAssignment]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<PracticeAssignment>> update(
    _i1.DatabaseSession session,
    List<PracticeAssignment> rows, {
    _i1.ColumnSelections<PracticeAssignmentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<PracticeAssignment>(
      rows,
      columns: columns?.call(PracticeAssignment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PracticeAssignment]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PracticeAssignment> updateRow(
    _i1.DatabaseSession session,
    PracticeAssignment row, {
    _i1.ColumnSelections<PracticeAssignmentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<PracticeAssignment>(
      row,
      columns: columns?.call(PracticeAssignment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PracticeAssignment] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PracticeAssignment?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<PracticeAssignmentUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<PracticeAssignment>(
      id,
      columnValues: columnValues(PracticeAssignment.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PracticeAssignment]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<PracticeAssignment>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<PracticeAssignmentUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<PracticeAssignmentTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PracticeAssignmentTable>? orderBy,
    _i1.OrderByListBuilder<PracticeAssignmentTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<PracticeAssignment>(
      columnValues: columnValues(PracticeAssignment.t.updateTable),
      where: where(PracticeAssignment.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PracticeAssignment.t),
      orderByList: orderByList?.call(PracticeAssignment.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [PracticeAssignment]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<PracticeAssignment>> delete(
    _i1.DatabaseSession session,
    List<PracticeAssignment> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<PracticeAssignment>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [PracticeAssignment].
  Future<PracticeAssignment> deleteRow(
    _i1.DatabaseSession session,
    PracticeAssignment row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PracticeAssignment>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<PracticeAssignment>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PracticeAssignmentTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<PracticeAssignment>(
      where: where(PracticeAssignment.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PracticeAssignmentTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<PracticeAssignment>(
      where: where?.call(PracticeAssignment.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PracticeAssignment] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PracticeAssignmentTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PracticeAssignment>(
      where: where(PracticeAssignment.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
