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

abstract class TrainingAttempt implements _i1.SerializableModel {
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
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
