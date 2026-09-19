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

abstract class EvidenceRetentionPurgeModel
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  EvidenceRetentionPurgeModel._({required this.now});

  factory EvidenceRetentionPurgeModel({required DateTime? now}) =
      _EvidenceRetentionPurgeModelImpl;

  factory EvidenceRetentionPurgeModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return EvidenceRetentionPurgeModel(
      now: jsonSerialization['now'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['now']),
    );
  }

  DateTime? now;

  /// Returns a shallow copy of this [EvidenceRetentionPurgeModel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EvidenceRetentionPurgeModel copyWith({DateTime? now});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EvidenceRetentionPurgeModel',
      if (now != null) 'now': now?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EvidenceRetentionPurgeModelImpl extends EvidenceRetentionPurgeModel {
  _EvidenceRetentionPurgeModelImpl({required DateTime? now})
    : super._(now: now);

  /// Returns a shallow copy of this [EvidenceRetentionPurgeModel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EvidenceRetentionPurgeModel copyWith({Object? now = _Undefined}) {
    return EvidenceRetentionPurgeModel(now: now is DateTime? ? now : this.now);
  }
}
