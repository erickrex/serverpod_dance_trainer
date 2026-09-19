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

abstract class TrainingCatalogEntry implements _i1.SerializableModel {
  TrainingCatalogEntry._({
    required this.routineId,
    required this.title,
    required this.durationMs,
    required this.version,
    required this.bundleJson,
    required this.mediaPath,
    required this.mediaSha256,
    required this.rankedAvailable,
  });

  factory TrainingCatalogEntry({
    required String routineId,
    required String title,
    required int durationMs,
    required String version,
    required String bundleJson,
    required String mediaPath,
    required String mediaSha256,
    required bool rankedAvailable,
  }) = _TrainingCatalogEntryImpl;

  factory TrainingCatalogEntry.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return TrainingCatalogEntry(
      routineId: jsonSerialization['routineId'] as String,
      title: jsonSerialization['title'] as String,
      durationMs: jsonSerialization['durationMs'] as int,
      version: jsonSerialization['version'] as String,
      bundleJson: jsonSerialization['bundleJson'] as String,
      mediaPath: jsonSerialization['mediaPath'] as String,
      mediaSha256: jsonSerialization['mediaSha256'] as String,
      rankedAvailable: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['rankedAvailable'],
      ),
    );
  }

  String routineId;

  String title;

  int durationMs;

  String version;

  String bundleJson;

  String mediaPath;

  String mediaSha256;

  bool rankedAvailable;

  /// Returns a shallow copy of this [TrainingCatalogEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TrainingCatalogEntry copyWith({
    String? routineId,
    String? title,
    int? durationMs,
    String? version,
    String? bundleJson,
    String? mediaPath,
    String? mediaSha256,
    bool? rankedAvailable,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TrainingCatalogEntry',
      'routineId': routineId,
      'title': title,
      'durationMs': durationMs,
      'version': version,
      'bundleJson': bundleJson,
      'mediaPath': mediaPath,
      'mediaSha256': mediaSha256,
      'rankedAvailable': rankedAvailable,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TrainingCatalogEntryImpl extends TrainingCatalogEntry {
  _TrainingCatalogEntryImpl({
    required String routineId,
    required String title,
    required int durationMs,
    required String version,
    required String bundleJson,
    required String mediaPath,
    required String mediaSha256,
    required bool rankedAvailable,
  }) : super._(
         routineId: routineId,
         title: title,
         durationMs: durationMs,
         version: version,
         bundleJson: bundleJson,
         mediaPath: mediaPath,
         mediaSha256: mediaSha256,
         rankedAvailable: rankedAvailable,
       );

  /// Returns a shallow copy of this [TrainingCatalogEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TrainingCatalogEntry copyWith({
    String? routineId,
    String? title,
    int? durationMs,
    String? version,
    String? bundleJson,
    String? mediaPath,
    String? mediaSha256,
    bool? rankedAvailable,
  }) {
    return TrainingCatalogEntry(
      routineId: routineId ?? this.routineId,
      title: title ?? this.title,
      durationMs: durationMs ?? this.durationMs,
      version: version ?? this.version,
      bundleJson: bundleJson ?? this.bundleJson,
      mediaPath: mediaPath ?? this.mediaPath,
      mediaSha256: mediaSha256 ?? this.mediaSha256,
      rankedAvailable: rankedAvailable ?? this.rankedAvailable,
    );
  }
}
