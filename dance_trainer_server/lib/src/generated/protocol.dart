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
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i3;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i4;
import 'greetings/greeting.dart' as _i5;
import 'training/board_entry.dart' as _i6;
import 'training/learner_profile.dart' as _i7;
import 'training/practice_assignment.dart' as _i8;
import 'training/practice_repetition.dart' as _i9;
import 'training/training_attempt.dart' as _i10;
import 'training/training_best.dart' as _i11;
import 'training/training_catalog_entry.dart' as _i12;
import 'training/training_chunk.dart' as _i13;
import 'training/training_error.dart' as _i14;
import 'package:dance_trainer_server/src/generated/training/training_catalog_entry.dart'
    as _i15;
import 'package:dance_trainer_server/src/generated/training/training_attempt.dart'
    as _i16;
import 'package:dance_trainer_server/src/generated/training/board_entry.dart'
    as _i17;
export 'greetings/greeting.dart';
export 'training/board_entry.dart';
export 'training/learner_profile.dart';
export 'training/practice_assignment.dart';
export 'training/practice_repetition.dart';
export 'training/training_attempt.dart';
export 'training/training_best.dart';
export 'training/training_catalog_entry.dart';
export 'training/training_chunk.dart';
export 'training/training_error.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'learner_profile',
      dartName: 'LearnerProfile',
      schema: 'public',
      module: 'dance_trainer',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'learner_profile_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'displayName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'leaderboardVisible',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'learner_profile_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'learner_user_unique',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'practice_assignment',
      dartName: 'PracticeAssignment',
      schema: 'public',
      module: 'dance_trainer',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'practice_assignment_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'sourceAttemptId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'routineId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'contentVersion',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'sectionId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'completedRepetitions',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'completed',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'practice_assignment_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'assignment_source_unique',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'sourceAttemptId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'practice_repetition',
      dartName: 'PracticeRepetition',
      schema: 'public',
      module: 'dance_trainer',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'practice_repetition_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'assignmentId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'attemptId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'practice_repetition_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'repetition_attempt_unique',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'attemptId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'training_attempt',
      dartName: 'TrainingAttempt',
      schema: 'public',
      module: 'dance_trainer',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'training_attempt_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'clientUuid',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'routineId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'contentVersion',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'modelVersion',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'mode',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'sectionId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'ticket',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'expiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'nextChunk',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'payloadBytes',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'resultJson',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'training_attempt_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'attempt_user_uuid_unique',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'clientUuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'attempt_history_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'training_best',
      dartName: 'TrainingBest',
      schema: 'public',
      module: 'dance_trainer',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'training_best_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'boardKey',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'attemptId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'score',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'achievedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'training_best_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'best_user_board_unique',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'boardKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'training_chunk',
      dartName: 'TrainingChunk',
      schema: 'public',
      module: 'dance_trainer',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'training_chunk_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'attemptId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'sequence',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'digest',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'payloadJson',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'training_chunk_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'chunk_sequence_unique',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'attemptId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'sequence',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i5.Greeting) {
      return _i5.Greeting.fromJson(data) as T;
    }
    if (t == _i6.BoardEntry) {
      return _i6.BoardEntry.fromJson(data) as T;
    }
    if (t == _i7.LearnerProfile) {
      return _i7.LearnerProfile.fromJson(data) as T;
    }
    if (t == _i8.PracticeAssignment) {
      return _i8.PracticeAssignment.fromJson(data) as T;
    }
    if (t == _i9.PracticeRepetition) {
      return _i9.PracticeRepetition.fromJson(data) as T;
    }
    if (t == _i10.TrainingAttempt) {
      return _i10.TrainingAttempt.fromJson(data) as T;
    }
    if (t == _i11.TrainingBest) {
      return _i11.TrainingBest.fromJson(data) as T;
    }
    if (t == _i12.TrainingCatalogEntry) {
      return _i12.TrainingCatalogEntry.fromJson(data) as T;
    }
    if (t == _i13.TrainingChunk) {
      return _i13.TrainingChunk.fromJson(data) as T;
    }
    if (t == _i14.TrainingError) {
      return _i14.TrainingError.fromJson(data) as T;
    }
    if (t == _i1.getType<_i5.Greeting?>()) {
      return (data != null ? _i5.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.BoardEntry?>()) {
      return (data != null ? _i6.BoardEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.LearnerProfile?>()) {
      return (data != null ? _i7.LearnerProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.PracticeAssignment?>()) {
      return (data != null ? _i8.PracticeAssignment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.PracticeRepetition?>()) {
      return (data != null ? _i9.PracticeRepetition.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.TrainingAttempt?>()) {
      return (data != null ? _i10.TrainingAttempt.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.TrainingBest?>()) {
      return (data != null ? _i11.TrainingBest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.TrainingCatalogEntry?>()) {
      return (data != null ? _i12.TrainingCatalogEntry.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i13.TrainingChunk?>()) {
      return (data != null ? _i13.TrainingChunk.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.TrainingError?>()) {
      return (data != null ? _i14.TrainingError.fromJson(data) : null) as T;
    }
    if (t == List<_i15.TrainingCatalogEntry>) {
      return (data as List)
              .map((e) => deserialize<_i15.TrainingCatalogEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i16.TrainingAttempt>) {
      return (data as List)
              .map((e) => deserialize<_i16.TrainingAttempt>(e))
              .toList()
          as T;
    }
    if (t == List<_i17.BoardEntry>) {
      return (data as List).map((e) => deserialize<_i17.BoardEntry>(e)).toList()
          as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i5.Greeting => 'Greeting',
      _i6.BoardEntry => 'BoardEntry',
      _i7.LearnerProfile => 'LearnerProfile',
      _i8.PracticeAssignment => 'PracticeAssignment',
      _i9.PracticeRepetition => 'PracticeRepetition',
      _i10.TrainingAttempt => 'TrainingAttempt',
      _i11.TrainingBest => 'TrainingBest',
      _i12.TrainingCatalogEntry => 'TrainingCatalogEntry',
      _i13.TrainingChunk => 'TrainingChunk',
      _i14.TrainingError => 'TrainingError',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst(
        'dance_trainer.',
        '',
      );
    }

    switch (data) {
      case _i5.Greeting():
        return 'Greeting';
      case _i6.BoardEntry():
        return 'BoardEntry';
      case _i7.LearnerProfile():
        return 'LearnerProfile';
      case _i8.PracticeAssignment():
        return 'PracticeAssignment';
      case _i9.PracticeRepetition():
        return 'PracticeRepetition';
      case _i10.TrainingAttempt():
        return 'TrainingAttempt';
      case _i11.TrainingBest():
        return 'TrainingBest';
      case _i12.TrainingCatalogEntry():
        return 'TrainingCatalogEntry';
      case _i13.TrainingChunk():
        return 'TrainingChunk';
      case _i14.TrainingError():
        return 'TrainingError';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i5.Greeting>(data['data']);
    }
    if (dataClassName == 'BoardEntry') {
      return deserialize<_i6.BoardEntry>(data['data']);
    }
    if (dataClassName == 'LearnerProfile') {
      return deserialize<_i7.LearnerProfile>(data['data']);
    }
    if (dataClassName == 'PracticeAssignment') {
      return deserialize<_i8.PracticeAssignment>(data['data']);
    }
    if (dataClassName == 'PracticeRepetition') {
      return deserialize<_i9.PracticeRepetition>(data['data']);
    }
    if (dataClassName == 'TrainingAttempt') {
      return deserialize<_i10.TrainingAttempt>(data['data']);
    }
    if (dataClassName == 'TrainingBest') {
      return deserialize<_i11.TrainingBest>(data['data']);
    }
    if (dataClassName == 'TrainingCatalogEntry') {
      return deserialize<_i12.TrainingCatalogEntry>(data['data']);
    }
    if (dataClassName == 'TrainingChunk') {
      return deserialize<_i13.TrainingChunk>(data['data']);
    }
    if (dataClassName == 'TrainingError') {
      return deserialize<_i14.TrainingError>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i4.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i7.LearnerProfile:
        return _i7.LearnerProfile.t;
      case _i8.PracticeAssignment:
        return _i8.PracticeAssignment.t;
      case _i9.PracticeRepetition:
        return _i9.PracticeRepetition.t;
      case _i10.TrainingAttempt:
        return _i10.TrainingAttempt.t;
      case _i11.TrainingBest:
        return _i11.TrainingBest.t;
      case _i13.TrainingChunk:
        return _i13.TrainingChunk.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'dance_trainer';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i4.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
