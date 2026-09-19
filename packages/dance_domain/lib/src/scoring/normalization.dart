import '../pose/geometry.dart';
import '../pose/landmark.dart';

/// A body-scale-normalized, mirror-corrected feature set for one frame,
/// derived from a [LandmarkFrame] per design.md "Scoring design" §Feature
/// normalization.
///
/// Deliberately keeps THREE kinds of feature, not one, because each is
/// invariant to different things and the origin project's bug was
/// collapsing distinct information into too few numbers:
///
/// - [jointAngles]: invariant to translation, uniform scale, and body
///   proportion. Good for "is the elbow bent the right amount".
/// - [limbDirections]: unit vectors, invariant to limb length. Good for
///   "is the arm pointing the right way", independent of how long the
///   dancer's arm is.
/// - [scaledPositions]: torso-centred, scale-normalized absolute position.
///   Deliberately NOT thrown away in favour of only angles/directions,
///   because a step is a translation of the whole body, not a joint
///   bend — normalizing it away would delete the exact thing a side-step
///   event needs to score (design.md: "Preserve ankle-relative and
///   trajectory features separately... normalizing away would delete the
///   exact thing a side step is scored on").
final class NormalizedFeatures {
  const NormalizedFeatures({
    required this.jointAngles,
    required this.limbDirections,
    required this.scaledPositions,
    required this.bodyScale,
  });

  /// Degrees, one entry per joint definition, keyed by the same names as
  /// [JointDefinition.name]. Null where unmeasurable — never 0.0 standing
  /// in for "could not measure" (the discipline `angleDegrees` already
  /// enforces; this map only carries its results forward).
  final Map<String, double?> jointAngles;

  /// Unit vectors, keyed by limb name. Null where the limb's landmarks are
  /// not both usable.
  final Map<String, Point2D?> limbDirections;

  /// Torso-centred, scale-normalized positions, keyed by landmark name.
  /// Null where the source landmark was not usable.
  final Map<String, Point2D?> scaledPositions;

  /// The body-scale estimate used to normalize [scaledPositions] and (via
  /// its role in the source landmarks) indirectly reflected in
  /// [limbDirections]'s reliability. Retained so a caller can tell how much
  /// to trust the normalization -- a body-scale estimate derived from a
  /// nearly-degenerate torso is unreliable even though the arithmetic still
  /// produces a number.
  final double bodyScale;
}

/// One derived joint angle: the angle at [vertex] between rays to [from]
/// and [to], all landmark names in [kLandmarkNames].
final class JointDefinition {
  const JointDefinition({
    required this.name,
    required this.from,
    required this.vertex,
    required this.to,
  });

  final String name;
  final String from;
  final String vertex;
  final String to;
}

/// One derived limb direction: the unit vector from [from] to [to].
final class LimbDefinition {
  const LimbDefinition({
    required this.name,
    required this.from,
    required this.to,
  });

  final String name;
  final String from;
  final String to;
}

/// The four genuinely independent joint bends, replacing the origin
/// project's eight angle names that reduced to four values (see
/// `tools/content_pipeline/pose_extract/README.md` "What changed").
const List<JointDefinition> kCoreJointDefinitions = <JointDefinition>[
  JointDefinition(
    name: 'leftElbow',
    from: 'leftShoulder',
    vertex: 'leftElbow',
    to: 'leftWrist',
  ),
  JointDefinition(
    name: 'rightElbow',
    from: 'rightShoulder',
    vertex: 'rightElbow',
    to: 'rightWrist',
  ),
  JointDefinition(
    name: 'leftKnee',
    from: 'leftHip',
    vertex: 'leftKnee',
    to: 'leftAnkle',
  ),
  JointDefinition(
    name: 'rightKnee',
    from: 'rightHip',
    vertex: 'rightKnee',
    to: 'rightAnkle',
  ),
];

/// Limbs whose absolute direction matters for the initial event vocabulary
/// (arm raises, stance changes) per requirements.md §6.1.
const List<LimbDefinition> kCoreLimbDefinitions = <LimbDefinition>[
  LimbDefinition(name: 'leftUpperArm', from: 'leftShoulder', to: 'leftElbow'),
  LimbDefinition(
    name: 'rightUpperArm',
    from: 'rightShoulder',
    to: 'rightElbow',
  ),
  LimbDefinition(name: 'leftForearm', from: 'leftElbow', to: 'leftWrist'),
  LimbDefinition(name: 'rightForearm', from: 'rightElbow', to: 'rightWrist'),
  LimbDefinition(name: 'leftThigh', from: 'leftHip', to: 'leftKnee'),
  LimbDefinition(name: 'rightThigh', from: 'rightHip', to: 'rightKnee'),
  LimbDefinition(name: 'leftShin', from: 'leftKnee', to: 'leftAnkle'),
  LimbDefinition(name: 'rightShin', from: 'rightKnee', to: 'rightAnkle'),
];

Point2D? _point(LandmarkFrame frame, String name) {
  final Landmark landmark = frame[name];
  if (!landmark.isUsable) {
    return null;
  }
  return Point2D(landmark.x!, landmark.y!);
}

/// A robust estimate of body scale in the SAME coordinate space as the
/// input landmarks (pixel space, or a single uniformly-normalized space --
/// never independently normalized per axis; see `angleDegrees`'s warning).
///
/// Uses shoulder-to-hip distance rather than, say, full height, because it
/// stays measurable even when the frame crops the ankles or the dancer's
/// feet are occluded -- the torso is the most reliably-visible span in a
/// dance video shot to include the whole body.
///
/// Returns null when the torso landmarks are not all usable, or when the
/// resulting scale is degenerate (near zero, meaning the shoulders and
/// hips landed on top of each other -- a bad detection, not a real body).
double? estimateBodyScale(LandmarkFrame frame) {
  final Point2D? leftShoulder = _point(frame, 'leftShoulder');
  final Point2D? rightShoulder = _point(frame, 'rightShoulder');
  final Point2D? leftHip = _point(frame, 'leftHip');
  final Point2D? rightHip = _point(frame, 'rightHip');
  if (leftShoulder == null ||
      rightShoulder == null ||
      leftHip == null ||
      rightHip == null) {
    return null;
  }

  final Point2D shoulderMid = (leftShoulder + rightShoulder).scaled(0.5);
  final Point2D hipMid = (leftHip + rightHip).scaled(0.5);
  final double torsoLength = shoulderMid.distanceTo(hipMid);

  const double epsilon = 1e-6;
  if (torsoLength < epsilon) {
    return null;
  }
  return torsoLength;
}

/// Derives [NormalizedFeatures] from one frame's landmarks.
///
/// [frame]'s coordinates must already be in a single undistorted space
/// (pixel space is expected — see `angleDegrees`'s warning about
/// independent per-axis normalization). This function does the
/// scale-normalization itself; it must not receive pre-normalized input
/// on top of its own.
///
/// Returns null when [estimateBodyScale] cannot produce a usable scale —
/// there is nothing meaningful to normalize by, and returning a
/// feature set built on a degenerate scale would silently corrupt every
/// downstream comparison, exactly the failure mode `angleDegrees` already
/// refuses for a single angle.
NormalizedFeatures? normalizeFeatures(LandmarkFrame frame) {
  final double? bodyScale = estimateBodyScale(frame);
  if (bodyScale == null) {
    return null;
  }

  final Point2D? leftShoulder = _point(frame, 'leftShoulder');
  final Point2D? rightShoulder = _point(frame, 'rightShoulder');
  final Point2D? leftHip = _point(frame, 'leftHip');
  final Point2D? rightHip = _point(frame, 'rightHip');
  // estimateBodyScale already guarantees these four are non-null when it
  // returns non-null, but re-deriving the torso centre from them here
  // rather than threading it through avoids a second parallel code path
  // that could drift out of sync with the scale estimate.
  final Point2D torsoCentre =
      (leftShoulder! + rightShoulder! + leftHip! + rightHip!).scaled(0.25);

  final Map<String, double?> jointAngles = <String, double?>{};
  for (final JointDefinition joint in kCoreJointDefinitions) {
    final Point2D? from = _point(frame, joint.from);
    final Point2D? vertex = _point(frame, joint.vertex);
    final Point2D? to = _point(frame, joint.to);
    jointAngles[joint.name] = (from == null || vertex == null || to == null)
        ? null
        : angleDegrees(vertex: vertex, a: from, c: to);
  }

  final Map<String, Point2D?> limbDirections = <String, Point2D?>{};
  for (final LimbDefinition limb in kCoreLimbDefinitions) {
    final Point2D? from = _point(frame, limb.from);
    final Point2D? to = _point(frame, limb.to);
    limbDirections[limb.name] = (from == null || to == null)
        ? null
        : unitDirection(from, to);
  }

  final Map<String, Point2D?> scaledPositions = <String, Point2D?>{};
  for (final String name in kLandmarkNames) {
    final Point2D? point = _point(frame, name);
    scaledPositions[name] = point == null
        ? null
        : (point - torsoCentre).scaled(1.0 / bodyScale);
  }

  return NormalizedFeatures(
    jointAngles: jointAngles,
    limbDirections: limbDirections,
    scaledPositions: scaledPositions,
    bodyScale: bodyScale,
  );
}
