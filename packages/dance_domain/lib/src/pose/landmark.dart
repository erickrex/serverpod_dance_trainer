/// The 17 COCO landmark names, in the order every pose source (v1 and v2
/// alike) and the ExecuTorch model output use. Order matters: several call
/// sites index parallel arrays by position rather than by name.
const List<String> kLandmarkNames = <String>[
  'nose',
  'leftEye',
  'rightEye',
  'leftEar',
  'rightEar',
  'leftShoulder',
  'rightShoulder',
  'leftElbow',
  'rightElbow',
  'leftWrist',
  'rightWrist',
  'leftHip',
  'rightHip',
  'leftKnee',
  'rightKnee',
  'leftAnkle',
  'rightAnkle',
];

/// The eight landmarks every scoreable event actually depends on. Coverage
/// is judged over these, not over all 17 (requirement 8.8, task 2.11):
/// measured on the preserved content, ~94% of frames have all eight core
/// landmarks confident but only ~59% have all seventeen, and the gap is the
/// face group, which nothing in the event vocabulary needs.
const List<String> kCoreLandmarkNames = <String>[
  'leftShoulder',
  'rightShoulder',
  'leftHip',
  'rightHip',
  'leftKnee',
  'rightKnee',
  'leftAnkle',
  'rightAnkle',
];

/// Whether a landmark observation should be trusted.
///
/// Deliberately three states, not a boolean. [lowConfidence] and [absent]
/// are both "do not trust this", but they are different signals for
/// diagnostics: a run with everything [lowConfidence] needs better lighting
/// or distance, while a run with everything [absent] has no dancer in
/// frame at all. Collapsing them to one boolean would hide that distinction
/// from a later debugging session.
enum LandmarkValidity {
  /// Confidence met or exceeded the configured threshold; trust the
  /// coordinates.
  observed,

  /// The model produced a low-confidence guess. Coordinates are present but
  /// must not be scored as fact.
  lowConfidence,

  /// No usable observation for this landmark in this frame. Coordinates are
  /// null, never zero (requirement 5.5) — (0, 0) is a real position and
  /// must never double as "unknown".
  absent,
}

/// One landmark observation: a position, a confidence and an explicit
/// validity.
///
/// [x] and [y] are null exactly when [validity] is [LandmarkValidity.absent].
/// This is enforced by the constructor, not left as a convention a caller
/// might forget — the origin project's bug this type exists to prevent was
/// exactly a forgotten convention (missing landmarks stored as `x: 0, y: 0,
/// confidence: 0`, indistinguishable from a real observation at the origin).
final class Landmark {
  Landmark({
    required this.x,
    required this.y,
    required this.confidence,
    required this.validity,
  }) {
    final absent = validity == LandmarkValidity.absent;
    if (absent ? (x != null || y != null) : (x == null || y == null)) {
      throw ArgumentError(
        'Absent landmarks require null coordinates; other landmarks require both coordinates.',
      );
    }
    if ((x != null && !x!.isFinite) || (y != null && !y!.isFinite)) {
      throw ArgumentError('Landmark coordinates must be finite.');
    }
    if (!confidence.isFinite || confidence < 0 || confidence > 1) {
      throw ArgumentError.value(
        confidence,
        'confidence',
        'Must be finite and in [0, 1].',
      );
    }
  }

  /// Constructs an absent landmark. There is exactly one way to spell
  /// "we did not see this" in this type.
  factory Landmark.absent() => Landmark(
    x: null,
    y: null,
    confidence: 0.0,
    validity: LandmarkValidity.absent,
  );

  /// Horizontal position in the caller's undistorted coordinate space, or null when [validity] is
  /// [LandmarkValidity.absent].
  final double? x;

  /// Vertical position in the same coordinate space, or null when [validity] is
  /// [LandmarkValidity.absent].
  final double? y;

  /// Model confidence in [0, 1]. Zero is legitimate — it is not itself a
  /// signal of absence; [validity] is the signal.
  final double confidence;

  final LandmarkValidity validity;

  bool get isUsable => validity == LandmarkValidity.observed;

  @override
  String toString() =>
      'Landmark(x: $x, y: $y, confidence: $confidence, validity: $validity)';

  @override
  bool operator ==(Object other) =>
      other is Landmark &&
      other.x == x &&
      other.y == y &&
      other.confidence == confidence &&
      other.validity == validity;

  @override
  int get hashCode => Object.hash(x, y, confidence, validity);
}

/// A full 17-landmark observation, keyed by name.
///
/// Deliberately a wrapper around a map rather than a positional list at the
/// public API: call sites read far more often by name (`pose['leftHip']`)
/// than by index, and a name typo fails loudly instead of silently reading
/// the wrong joint.
final class LandmarkFrame {
  LandmarkFrame(Map<String, Landmark> landmarks)
    : _landmarks = Map.unmodifiable(landmarks) {
    if (landmarks.keys.any((name) => !kLandmarkNames.contains(name))) {
      throw ArgumentError('Unknown landmark name.');
    }
    final Set<String> missing = kLandmarkNames.toSet()
      ..removeAll(landmarks.keys);
    if (missing.isNotEmpty) {
      throw ArgumentError(
        'LandmarkFrame is missing required landmarks: ${missing.join(', ')}. '
        'Use Landmark.absent() for a landmark with no observation, never '
        'omit the key.',
      );
    }
  }

  final Map<String, Landmark> _landmarks;

  Landmark operator [](String name) {
    final Landmark? landmark = _landmarks[name];
    if (landmark == null) {
      throw ArgumentError.value(name, 'name', 'not a known landmark name');
    }
    return landmark;
  }

  /// True when every landmark in [names] is [LandmarkValidity.observed].
  bool allObserved(Iterable<String> names) =>
      names.every((String name) => this[name].isUsable);

  /// True when every one of [kCoreLandmarkNames] is observed. This is the
  /// coverage question the scorer actually asks, not "are all 17 present".
  bool get hasCoreCoverage => allObserved(kCoreLandmarkNames);
}
