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

abstract class PracticeAssignment implements _i1.SerializableModel {
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String userId;

  int sourceAttemptId;

  String routineId;

  String contentVersion;

  String sectionId;

  int completedRepetitions;

  bool completed;

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
