import 'package:dance_domain/dance_domain.dart';
import 'package:test/test.dart';

/// Builds a LandmarkFrame from a sparse pixel-space map; anything not given
/// is Landmark.absent(). Coordinates are pixel-space by convention (this
/// is the coordinate discipline `angleDegrees` requires and normalization
/// depends on).
LandmarkFrame _frame(Map<String, (double, double)> pixelPositions) {
  final Map<String, Landmark> landmarks = <String, Landmark>{
    for (final String name in kLandmarkNames) name: Landmark.absent(),
  };
  for (final MapEntry<String, (double, double)> entry
      in pixelPositions.entries) {
    landmarks[entry.key] = Landmark(
      x: entry.value.$1,
      y: entry.value.$2,
      confidence: 0.9,
      validity: LandmarkValidity.observed,
    );
  }
  return LandmarkFrame(landmarks);
}

void main() {
  group('estimateBodyScale', () {
    test('returns torso length when all four torso landmarks are usable', () {
      final LandmarkFrame frame = _frame({
        'leftShoulder': (400, 200),
        'rightShoulder': (600, 200),
        'leftHip': (420, 500),
        'rightHip': (580, 500),
      });
      final double? scale = estimateBodyScale(frame);
      expect(scale, isNotNull);
      // shoulder midpoint (500,200), hip midpoint (500,500) -> length 300.
      expect(scale, closeTo(300.0, 1e-9));
    });

    test('returns null when a torso landmark is absent', () {
      final LandmarkFrame frame = _frame({
        'leftShoulder': (400, 200),
        'rightShoulder': (600, 200),
        'leftHip': (420, 500),
        // rightHip absent
      });
      expect(estimateBodyScale(frame), isNull);
    });

    test('returns null for a degenerate (near-zero-length) torso rather than '
        'a division-prone tiny number', () {
      final LandmarkFrame frame = _frame({
        'leftShoulder': (500, 300),
        'rightShoulder': (500, 300),
        'leftHip': (500, 300),
        'rightHip': (500, 300),
      });
      expect(estimateBodyScale(frame), isNull);
    });
  });

  group('normalizeFeatures', () {
    test('returns null when body scale is unavailable', () {
      final LandmarkFrame frame = _frame({'leftShoulder': (1, 1)});
      expect(normalizeFeatures(frame), isNull);
    });

    test('computes a joint angle for a fully-observed joint', () {
      // Straight left arm: shoulder, elbow, wrist collinear -> 180 degrees.
      final LandmarkFrame frame = _frame({
        'leftShoulder': (400, 200),
        'rightShoulder': (600, 200),
        'leftHip': (420, 500),
        'rightHip': (580, 500),
        'leftElbow': (400, 350),
        'leftWrist': (400, 500),
      });
      final NormalizedFeatures? features = normalizeFeatures(frame);
      expect(features, isNotNull);
      expect(features!.jointAngles['leftElbow'], closeTo(180.0, 1e-6));
    });

    test('a joint with a missing landmark is null in jointAngles, not 0.0', () {
      final LandmarkFrame frame = _frame({
        'leftShoulder': (400, 200),
        'rightShoulder': (600, 200),
        'leftHip': (420, 500),
        'rightHip': (580, 500),
        // leftElbow and leftWrist both absent
      });
      final NormalizedFeatures? features = normalizeFeatures(frame);
      expect(features!.jointAngles['leftElbow'], isNull);
    });

    test('limb direction is a unit vector', () {
      final LandmarkFrame frame = _frame({
        'leftShoulder': (400, 200),
        'rightShoulder': (600, 200),
        'leftHip': (420, 500),
        'rightHip': (580, 500),
        'leftElbow': (400, 350),
      });
      final NormalizedFeatures? features = normalizeFeatures(frame);
      final Point2D? direction = features!.limbDirections['leftUpperArm'];
      expect(direction, isNotNull);
      expect(direction!.length, closeTo(1.0, 1e-9));
    });

    test('scaledPositions centres on the torso midpoint and divides by body '
        'scale, so the same relative pose reads the same regardless of '
        'where in frame or how large the dancer is', () {
      final LandmarkFrame closeUp = _frame({
        'leftShoulder': (400, 200),
        'rightShoulder': (600, 200),
        'leftHip': (420, 500),
        'rightHip': (580, 500),
        'leftAnkle': (500, 800), // straight below torso centre
      });
      // Same pose, translated and scaled up 2x (dancer closer to camera,
      // standing elsewhere in frame).
      final LandmarkFrame fartherRight = _frame({
        'leftShoulder': (800, 400),
        'rightShoulder': (1200, 400),
        'leftHip': (840, 1000),
        'rightHip': (1160, 1000),
        'leftAnkle': (1000, 1600),
      });

      final Point2D closeAnkle = normalizeFeatures(
        closeUp,
      )!.scaledPositions['leftAnkle']!;
      final Point2D farAnkle = normalizeFeatures(
        fartherRight,
      )!.scaledPositions['leftAnkle']!;

      expect(closeAnkle.x, closeTo(farAnkle.x, 1e-6));
      expect(closeAnkle.y, closeTo(farAnkle.y, 1e-6));
    });

    test('preserves lateral (ankle) displacement rather than normalizing it '
        'away -- design.md: a side step must remain scoreable', () {
      final LandmarkFrame feetTogether = _frame({
        'leftShoulder': (400, 200),
        'rightShoulder': (600, 200),
        'leftHip': (420, 500),
        'rightHip': (580, 500),
        'leftAnkle': (500, 800),
      });
      final LandmarkFrame steppedOut = _frame({
        'leftShoulder': (400, 200),
        'rightShoulder': (600, 200),
        'leftHip': (420, 500),
        'rightHip': (580, 500),
        'leftAnkle': (250, 800), // stepped far to the side
      });

      final Point2D togetherAnkle = normalizeFeatures(
        feetTogether,
      )!.scaledPositions['leftAnkle']!;
      final Point2D steppedAnkle = normalizeFeatures(
        steppedOut,
      )!.scaledPositions['leftAnkle']!;

      expect(
        (steppedAnkle.x - togetherAnkle.x).abs(),
        greaterThan(0.3),
        reason:
            'the two ankle positions must read as meaningfully '
            'different, or a side-step event could never be scored',
      );
    });
  });
}
