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
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'greetings/greeting.dart' as _i2;
import 'training/board_entry.dart' as _i3;
import 'training/learner_profile.dart' as _i4;
import 'training/practice_assignment.dart' as _i5;
import 'training/training_attempt.dart' as _i6;
import 'training/training_catalog_entry.dart' as _i7;
import 'training/training_error.dart' as _i8;
import 'package:dance_trainer_client/src/protocol/training/training_catalog_entry.dart'
    as _i9;
import 'package:dance_trainer_client/src/protocol/training/training_attempt.dart'
    as _i10;
import 'package:dance_trainer_client/src/protocol/training/board_entry.dart'
    as _i11;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i12;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i13;
export 'greetings/greeting.dart';
export 'training/board_entry.dart';
export 'training/learner_profile.dart';
export 'training/practice_assignment.dart';
export 'training/training_attempt.dart';
export 'training/training_catalog_entry.dart';
export 'training/training_error.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

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

    if (t == _i2.Greeting) {
      return _i2.Greeting.fromJson(data) as T;
    }
    if (t == _i3.BoardEntry) {
      return _i3.BoardEntry.fromJson(data) as T;
    }
    if (t == _i4.LearnerProfile) {
      return _i4.LearnerProfile.fromJson(data) as T;
    }
    if (t == _i5.PracticeAssignment) {
      return _i5.PracticeAssignment.fromJson(data) as T;
    }
    if (t == _i6.TrainingAttempt) {
      return _i6.TrainingAttempt.fromJson(data) as T;
    }
    if (t == _i7.TrainingCatalogEntry) {
      return _i7.TrainingCatalogEntry.fromJson(data) as T;
    }
    if (t == _i8.TrainingError) {
      return _i8.TrainingError.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Greeting?>()) {
      return (data != null ? _i2.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.BoardEntry?>()) {
      return (data != null ? _i3.BoardEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.LearnerProfile?>()) {
      return (data != null ? _i4.LearnerProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.PracticeAssignment?>()) {
      return (data != null ? _i5.PracticeAssignment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.TrainingAttempt?>()) {
      return (data != null ? _i6.TrainingAttempt.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.TrainingCatalogEntry?>()) {
      return (data != null ? _i7.TrainingCatalogEntry.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.TrainingError?>()) {
      return (data != null ? _i8.TrainingError.fromJson(data) : null) as T;
    }
    if (t == List<_i9.TrainingCatalogEntry>) {
      return (data as List)
              .map((e) => deserialize<_i9.TrainingCatalogEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i10.TrainingAttempt>) {
      return (data as List)
              .map((e) => deserialize<_i10.TrainingAttempt>(e))
              .toList()
          as T;
    }
    if (t == List<_i11.BoardEntry>) {
      return (data as List).map((e) => deserialize<_i11.BoardEntry>(e)).toList()
          as T;
    }
    try {
      return _i12.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i13.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.Greeting => 'Greeting',
      _i3.BoardEntry => 'BoardEntry',
      _i4.LearnerProfile => 'LearnerProfile',
      _i5.PracticeAssignment => 'PracticeAssignment',
      _i6.TrainingAttempt => 'TrainingAttempt',
      _i7.TrainingCatalogEntry => 'TrainingCatalogEntry',
      _i8.TrainingError => 'TrainingError',
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
      case _i2.Greeting():
        return 'Greeting';
      case _i3.BoardEntry():
        return 'BoardEntry';
      case _i4.LearnerProfile():
        return 'LearnerProfile';
      case _i5.PracticeAssignment():
        return 'PracticeAssignment';
      case _i6.TrainingAttempt():
        return 'TrainingAttempt';
      case _i7.TrainingCatalogEntry():
        return 'TrainingCatalogEntry';
      case _i8.TrainingError():
        return 'TrainingError';
    }
    className = _i12.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i13.Protocol().getClassNameForObject(data);
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
      return deserialize<_i2.Greeting>(data['data']);
    }
    if (dataClassName == 'BoardEntry') {
      return deserialize<_i3.BoardEntry>(data['data']);
    }
    if (dataClassName == 'LearnerProfile') {
      return deserialize<_i4.LearnerProfile>(data['data']);
    }
    if (dataClassName == 'PracticeAssignment') {
      return deserialize<_i5.PracticeAssignment>(data['data']);
    }
    if (dataClassName == 'TrainingAttempt') {
      return deserialize<_i6.TrainingAttempt>(data['data']);
    }
    if (dataClassName == 'TrainingCatalogEntry') {
      return deserialize<_i7.TrainingCatalogEntry>(data['data']);
    }
    if (dataClassName == 'TrainingError') {
      return deserialize<_i8.TrainingError>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i12.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i13.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

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
      return _i12.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i13.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
