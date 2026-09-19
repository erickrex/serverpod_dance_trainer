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

abstract class TrainingAttempt
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  TrainingAttempt._({
    this.id,
    required this.userId,
    required this.clientUuid,
    required this.routineId,
    required this.contentVersion,
    required this.modelVersion,
    required this.mode,
    this.sectionId,
    required this.ticket,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    required this.nextChunk,
    required this.payloadBytes,
    this.resultJson,
  });

  factory TrainingAttempt({
    int? id,
    required String userId,
    required String clientUuid,
    required String routineId,
    required String contentVersion,
    required String modelVersion,
    required String mode,
    String? sectionId,
    required String ticket,
    required DateTime createdAt,
    required DateTime expiresAt,
    required String status,
    required int nextChunk,
    required int payloadBytes,
    String? resultJson,
  }) = _TrainingAttemptImpl;

  factory TrainingAttempt.fromJson(Map<String, dynamic> jsonSerialization) {
    return TrainingAttempt(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      clientUuid: jsonSerialization['clientUuid'] as String,
      routineId: jsonSerialization['routineId'] as String,
      contentVersion: jsonSerialization['contentVersion'] as String,
      modelVersion: jsonSerialization['modelVersion'] as String,
      mode: jsonSerialization['mode'] as String,
      sectionId: jsonSerialization['sectionId'] as String?,
      ticket: jsonSerialization['ticket'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      status: jsonSerialization['status'] as String,
      nextChunk: jsonSerialization['nextChunk'] as int,
      payloadBytes: jsonSerialization['payloadBytes'] as int,
      resultJson: jsonSerialization['resultJson'] as String?,
    );
  }

  static final t = TrainingAttemptTable();

  static const db = TrainingAttemptRepository._();

  @override
  int? id;

  String userId;

  String clientUuid;

  String routineId;

  String contentVersion;

  String modelVersion;

  String mode;

  String? sectionId;

  String ticket;

  DateTime createdAt;

  DateTime expiresAt;

  String status;

  int nextChunk;

  int payloadBytes;

  String? resultJson;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [TrainingAttempt]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TrainingAttempt copyWith({
    int? id,
    String? userId,
    String? clientUuid,
    String? routineId,
    String? contentVersion,
    String? modelVersion,
    String? mode,
    String? sectionId,
    String? ticket,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? status,
    int? nextChunk,
    int? payloadBytes,
    String? resultJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TrainingAttempt',
      if (id != null) 'id': id,
      'userId': userId,
      'clientUuid': clientUuid,
      'routineId': routineId,
      'contentVersion': contentVersion,
      'modelVersion': modelVersion,
      'mode': mode,
      if (sectionId != null) 'sectionId': sectionId,
      'ticket': ticket,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      'status': status,
      'nextChunk': nextChunk,
      'payloadBytes': payloadBytes,
      if (resultJson != null) 'resultJson': resultJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TrainingAttempt',
      if (id != null) 'id': id,
      'userId': userId,
      'clientUuid': clientUuid,
      'routineId': routineId,
      'contentVersion': contentVersion,
      'modelVersion': modelVersion,
      'mode': mode,
      if (sectionId != null) 'sectionId': sectionId,
      'ticket': ticket,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      'status': status,
      'nextChunk': nextChunk,
      'payloadBytes': payloadBytes,
      if (resultJson != null) 'resultJson': resultJson,
    };
  }

  static TrainingAttemptInclude include() {
    return TrainingAttemptInclude._();
  }

  static TrainingAttemptIncludeList includeList({
    _i1.WhereExpressionBuilder<TrainingAttemptTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrainingAttemptTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrainingAttemptTable>? orderByList,
    TrainingAttemptInclude? include,
  }) {
    return TrainingAttemptIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TrainingAttempt.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TrainingAttempt.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TrainingAttemptImpl extends TrainingAttempt {
  _TrainingAttemptImpl({
    int? id,
    required String userId,
    required String clientUuid,
    required String routineId,
    required String contentVersion,
    required String modelVersion,
    required String mode,
    String? sectionId,
    required String ticket,
    required DateTime createdAt,
    required DateTime expiresAt,
    required String status,
    required int nextChunk,
    required int payloadBytes,
    String? resultJson,
  }) : super._(
         id: id,
         userId: userId,
         clientUuid: clientUuid,
         routineId: routineId,
         contentVersion: contentVersion,
         modelVersion: modelVersion,
         mode: mode,
         sectionId: sectionId,
         ticket: ticket,
         createdAt: createdAt,
         expiresAt: expiresAt,
         status: status,
         nextChunk: nextChunk,
         payloadBytes: payloadBytes,
         resultJson: resultJson,
       );

  /// Returns a shallow copy of this [TrainingAttempt]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TrainingAttempt copyWith({
    Object? id = _Undefined,
    String? userId,
    String? clientUuid,
    String? routineId,
    String? contentVersion,
    String? modelVersion,
    String? mode,
    Object? sectionId = _Undefined,
    String? ticket,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? status,
    int? nextChunk,
    int? payloadBytes,
    Object? resultJson = _Undefined,
  }) {
    return TrainingAttempt(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      clientUuid: clientUuid ?? this.clientUuid,
      routineId: routineId ?? this.routineId,
      contentVersion: contentVersion ?? this.contentVersion,
      modelVersion: modelVersion ?? this.modelVersion,
      mode: mode ?? this.mode,
      sectionId: sectionId is String? ? sectionId : this.sectionId,
      ticket: ticket ?? this.ticket,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      nextChunk: nextChunk ?? this.nextChunk,
      payloadBytes: payloadBytes ?? this.payloadBytes,
      resultJson: resultJson is String? ? resultJson : this.resultJson,
    );
  }
}

class TrainingAttemptUpdateTable extends _i1.UpdateTable<TrainingAttemptTable> {
  TrainingAttemptUpdateTable(super.table);

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> clientUuid(String value) => _i1.ColumnValue(
    table.clientUuid,
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

  _i1.ColumnValue<String, String> modelVersion(String value) => _i1.ColumnValue(
    table.modelVersion,
    value,
  );

  _i1.ColumnValue<String, String> mode(String value) => _i1.ColumnValue(
    table.mode,
    value,
  );

  _i1.ColumnValue<String, String> sectionId(String? value) => _i1.ColumnValue(
    table.sectionId,
    value,
  );

  _i1.ColumnValue<String, String> ticket(String value) => _i1.ColumnValue(
    table.ticket,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _i1.ColumnValue(
        table.expiresAt,
        value,
      );

  _i1.ColumnValue<String, String> status(String value) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<int, int> nextChunk(int value) => _i1.ColumnValue(
    table.nextChunk,
    value,
  );

  _i1.ColumnValue<int, int> payloadBytes(int value) => _i1.ColumnValue(
    table.payloadBytes,
    value,
  );

  _i1.ColumnValue<String, String> resultJson(String? value) => _i1.ColumnValue(
    table.resultJson,
    value,
  );
}

class TrainingAttemptTable extends _i1.Table<int?> {
  TrainingAttemptTable({super.tableRelation})
    : super(tableName: 'training_attempt') {
    updateTable = TrainingAttemptUpdateTable(this);
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    clientUuid = _i1.ColumnString(
      'clientUuid',
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
    modelVersion = _i1.ColumnString(
      'modelVersion',
      this,
    );
    mode = _i1.ColumnString(
      'mode',
      this,
    );
    sectionId = _i1.ColumnString(
      'sectionId',
      this,
    );
    ticket = _i1.ColumnString(
      'ticket',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    expiresAt = _i1.ColumnDateTime(
      'expiresAt',
      this,
    );
    status = _i1.ColumnString(
      'status',
      this,
    );
    nextChunk = _i1.ColumnInt(
      'nextChunk',
      this,
    );
    payloadBytes = _i1.ColumnInt(
      'payloadBytes',
      this,
    );
    resultJson = _i1.ColumnString(
      'resultJson',
      this,
    );
  }

  late final TrainingAttemptUpdateTable updateTable;

  late final _i1.ColumnString userId;

  late final _i1.ColumnString clientUuid;

  late final _i1.ColumnString routineId;

  late final _i1.ColumnString contentVersion;

  late final _i1.ColumnString modelVersion;

  late final _i1.ColumnString mode;

  late final _i1.ColumnString sectionId;

  late final _i1.ColumnString ticket;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime expiresAt;

  late final _i1.ColumnString status;

  late final _i1.ColumnInt nextChunk;

  late final _i1.ColumnInt payloadBytes;

  late final _i1.ColumnString resultJson;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    clientUuid,
    routineId,
    contentVersion,
    modelVersion,
    mode,
    sectionId,
    ticket,
    createdAt,
    expiresAt,
    status,
    nextChunk,
    payloadBytes,
    resultJson,
  ];
}

class TrainingAttemptInclude extends _i1.IncludeObject {
  TrainingAttemptInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => TrainingAttempt.t;
}

class TrainingAttemptIncludeList extends _i1.IncludeList {
  TrainingAttemptIncludeList._({
    _i1.WhereExpressionBuilder<TrainingAttemptTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TrainingAttempt.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => TrainingAttempt.t;
}

class TrainingAttemptRepository {
  const TrainingAttemptRepository._();

  /// Returns a list of [TrainingAttempt]s matching the given query parameters.
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
  Future<List<TrainingAttempt>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TrainingAttemptTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrainingAttemptTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrainingAttemptTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TrainingAttempt>(
      where: where?.call(TrainingAttempt.t),
      orderBy: orderBy?.call(TrainingAttempt.t),
      orderByList: orderByList?.call(TrainingAttempt.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TrainingAttempt] matching the given query parameters.
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
  Future<TrainingAttempt?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TrainingAttemptTable>? where,
    int? offset,
    _i1.OrderByBuilder<TrainingAttemptTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TrainingAttemptTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TrainingAttempt>(
      where: where?.call(TrainingAttempt.t),
      orderBy: orderBy?.call(TrainingAttempt.t),
      orderByList: orderByList?.call(TrainingAttempt.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TrainingAttempt] by its [id] or null if no such row exists.
  Future<TrainingAttempt?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TrainingAttempt>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TrainingAttempt]s in the list and returns the inserted rows.
  ///
  /// The returned [TrainingAttempt]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<TrainingAttempt>> insert(
    _i1.DatabaseSession session,
    List<TrainingAttempt> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<TrainingAttempt>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [TrainingAttempt] and returns the inserted row.
  ///
  /// The returned [TrainingAttempt] will have its `id` field set.
  Future<TrainingAttempt> insertRow(
    _i1.DatabaseSession session,
    TrainingAttempt row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TrainingAttempt>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TrainingAttempt]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TrainingAttempt>> update(
    _i1.DatabaseSession session,
    List<TrainingAttempt> rows, {
    _i1.ColumnSelections<TrainingAttemptTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TrainingAttempt>(
      rows,
      columns: columns?.call(TrainingAttempt.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TrainingAttempt]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TrainingAttempt> updateRow(
    _i1.DatabaseSession session,
    TrainingAttempt row, {
    _i1.ColumnSelections<TrainingAttemptTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TrainingAttempt>(
      row,
      columns: columns?.call(TrainingAttempt.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TrainingAttempt] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TrainingAttempt?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<TrainingAttemptUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<TrainingAttempt>(
      id,
      columnValues: columnValues(TrainingAttempt.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TrainingAttempt]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<TrainingAttempt>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<TrainingAttemptUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<TrainingAttemptTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TrainingAttemptTable>? orderBy,
    _i1.OrderByListBuilder<TrainingAttemptTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<TrainingAttempt>(
      columnValues: columnValues(TrainingAttempt.t.updateTable),
      where: where(TrainingAttempt.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TrainingAttempt.t),
      orderByList: orderByList?.call(TrainingAttempt.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [TrainingAttempt]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TrainingAttempt>> delete(
    _i1.DatabaseSession session,
    List<TrainingAttempt> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TrainingAttempt>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TrainingAttempt].
  Future<TrainingAttempt> deleteRow(
    _i1.DatabaseSession session,
    TrainingAttempt row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TrainingAttempt>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TrainingAttempt>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TrainingAttemptTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TrainingAttempt>(
      where: where(TrainingAttempt.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TrainingAttemptTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TrainingAttempt>(
      where: where?.call(TrainingAttempt.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TrainingAttempt] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TrainingAttemptTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TrainingAttempt>(
      where: where(TrainingAttempt.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
