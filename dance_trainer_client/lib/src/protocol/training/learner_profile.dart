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

abstract class LearnerProfile implements _i1.SerializableModel {
  LearnerProfile._({
    this.id,
    required this.userId,
    required this.displayName,
    required this.leaderboardVisible,
  });

  factory LearnerProfile({
    int? id,
    required String userId,
    required String displayName,
    required bool leaderboardVisible,
  }) = _LearnerProfileImpl;

  factory LearnerProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return LearnerProfile(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      displayName: jsonSerialization['displayName'] as String,
      leaderboardVisible: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['leaderboardVisible'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String userId;

  String displayName;

  bool leaderboardVisible;

  /// Returns a shallow copy of this [LearnerProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LearnerProfile copyWith({
    int? id,
    String? userId,
    String? displayName,
    bool? leaderboardVisible,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LearnerProfile',
      if (id != null) 'id': id,
      'userId': userId,
      'displayName': displayName,
      'leaderboardVisible': leaderboardVisible,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LearnerProfileImpl extends LearnerProfile {
  _LearnerProfileImpl({
    int? id,
    required String userId,
    required String displayName,
    required bool leaderboardVisible,
  }) : super._(
         id: id,
         userId: userId,
         displayName: displayName,
         leaderboardVisible: leaderboardVisible,
       );

  /// Returns a shallow copy of this [LearnerProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LearnerProfile copyWith({
    Object? id = _Undefined,
    String? userId,
    String? displayName,
    bool? leaderboardVisible,
  }) {
    return LearnerProfile(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      leaderboardVisible: leaderboardVisible ?? this.leaderboardVisible,
    );
  }
}
