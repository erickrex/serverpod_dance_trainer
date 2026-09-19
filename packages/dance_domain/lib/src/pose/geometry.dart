import 'dart:math' as math;

/// A 2D point in whatever coordinate space the caller is working in.
///
/// Deliberately a plain value type with no notion of "normalized" or
/// "pixel" baked in — see the warning on [angleDegrees]. Callers are
/// responsible for staying in one consistent space per calculation.
final class Point2D {
  Point2D(this.x, this.y) {
    if (!x.isFinite || !y.isFinite) {
      throw ArgumentError('Point coordinates must be finite.');
    }
  }

  final double x;
  final double y;

  Point2D operator -(Point2D other) => Point2D(x - other.x, y - other.y);

  Point2D operator +(Point2D other) => Point2D(x + other.x, y + other.y);

  Point2D scaled(double factor) => Point2D(x * factor, y * factor);

  double get length => math.sqrt(x * x + y * y);

  double distanceTo(Point2D other) => (this - other).length;

  double dot(Point2D other) => x * other.x + y * other.y;

  @override
  String toString() => 'Point2D($x, $y)';

  @override
  bool operator ==(Object other) =>
      other is Point2D && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// The angle at [vertex] between rays to [a] and [c], in degrees, in
/// [0, 180].
///
/// Returns null when either ray has (near) zero length — a degenerate
/// triangle has no defined angle, and null is how this package always
/// spells "could not measure" (requirement 5.5's absent-landmark discipline
/// extends to every derived quantity, not just raw landmarks). 0.0 is a
/// real, fully-folded joint angle and must never stand in for "unmeasurable".
///
/// CRITICAL — coordinate space: the three points must be in a space where
/// one unit means the same physical distance along x as along y (pixel
/// space, or a space normalized by ONE shared scale for both axes).
///
/// Do not pass points normalized independently as x/width and y/height.
/// Dividing the two axes by different numbers shears the space, and this
/// function has no way to detect that its inputs were shorn — it will
/// return a confident, wrong number. This is not a hypothetical: the origin
/// project's `preprocess_video_yolov8.py` did exactly this (angles computed
/// from `x/width, y/height` coordinates on 1280x720 video), and every angle
/// in the preserved v1 pose files is affected. See
/// `tools/content_pipeline/pose_extract/README.md` for the measured
/// consequence and the fix in `extract_poses.py`.
double? angleDegrees({
  required Point2D vertex,
  required Point2D a,
  required Point2D c,
}) {
  final Point2D v1 = a - vertex;
  final Point2D v2 = c - vertex;
  final double n1 = v1.length;
  final double n2 = v2.length;
  const double epsilon = 1e-9;
  if (n1 < epsilon || n2 < epsilon) {
    return null;
  }
  final double cosine = (v1.dot(v2) / (n1 * n2)).clamp(-1.0, 1.0);
  return math.acos(cosine) * 180.0 / math.pi;
}

/// The unit vector from [from] to [to], or null when they coincide.
///
/// Used by feature normalization for limb-direction features (design.md
/// "Scoring design" §Feature normalization): direction is compared
/// independent of the limb's absolute length, which is itself normalized
/// separately by body scale so it is not thrown away, only factored out of
/// the direction feature specifically.
Point2D? unitDirection(Point2D from, Point2D to) {
  final Point2D delta = to - from;
  final double length = delta.length;
  const double epsilon = 1e-9;
  if (length < epsilon) {
    return null;
  }
  return delta.scaled(1.0 / length);
}
