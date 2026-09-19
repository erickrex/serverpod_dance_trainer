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

abstract class BoardEntry implements _i1.SerializableModel {
  BoardEntry._({
    required this.displayName,
    required this.score,
    required this.achievedAt,
  });

  factory BoardEntry({
    required String displayName,
    required int score,
    required DateTime achievedAt,
  }) = _BoardEntryImpl;

  factory BoardEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return BoardEntry(
      displayName: jsonSerialization['displayName'] as String,
      score: jsonSerialization['score'] as int,
      achievedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['achievedAt'],
      ),
    );
  }

  String displayName;

  int score;

  DateTime achievedAt;

  /// Returns a shallow copy of this [BoardEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BoardEntry copyWith({
    String? displayName,
    int? score,
    DateTime? achievedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BoardEntry',
      'displayName': displayName,
      'score': score,
      'achievedAt': achievedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _BoardEntryImpl extends BoardEntry {
  _BoardEntryImpl({
    required String displayName,
    required int score,
    required DateTime achievedAt,
  }) : super._(
         displayName: displayName,
         score: score,
         achievedAt: achievedAt,
       );

  /// Returns a shallow copy of this [BoardEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BoardEntry copyWith({
    String? displayName,
    int? score,
    DateTime? achievedAt,
  }) {
    return BoardEntry(
      displayName: displayName ?? this.displayName,
      score: score ?? this.score,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }
}
