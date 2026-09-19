import 'package:dance_domain/dance_domain.dart';
import 'package:test/test.dart';

void main() {
  group('angleDegrees', () {
    test('right angle reads as 90 degrees', () {
      // vertex at origin, one ray along +x, one along +y.
      final double? angle = angleDegrees(
        vertex: Point2D(0, 0),
        a: Point2D(1, 0),
        c: Point2D(0, 1),
      );
      expect(angle, closeTo(90.0, 1e-9));
    });

    test('straight limb reads as 180 degrees', () {
      final double? angle = angleDegrees(
        vertex: Point2D(0, 0),
        a: Point2D(-1, 0),
        c: Point2D(1, 0),
      );
      expect(angle, closeTo(180.0, 1e-9));
    });

    test('fully folded limb reads as 0 degrees, distinct from null', () {
      final double? angle = angleDegrees(
        vertex: Point2D(0, 0),
        a: Point2D(1, 0),
        c: Point2D(1, 0),
      );
      expect(angle, closeTo(0.0, 1e-9));
      expect(angle, isNotNull); // 0.0 is a real measurement, not "unknown".
    });

    test('degenerate triangle (zero-length ray) returns null, not 0', () {
      final double? angle = angleDegrees(
        vertex: Point2D(5, 5),
        a: Point2D(5, 5), // coincides with vertex
        c: Point2D(9, 5),
      );
      expect(
        angle,
        isNull,
        reason:
            'a zero-length ray has no defined angle; this must not '
            'silently read as 0.0',
      );
    });

    test('is invariant to translation', () {
      final double? base = angleDegrees(
        vertex: Point2D(0, 0),
        a: Point2D(2, 0),
        c: Point2D(0, 3),
      );
      final double? translated = angleDegrees(
        vertex: Point2D(100, -50),
        a: Point2D(102, -50),
        c: Point2D(100, -47),
      );
      expect(translated, closeTo(base!, 1e-9));
    });

    test('is invariant to uniform scale', () {
      final double? base = angleDegrees(
        vertex: Point2D(0, 0),
        a: Point2D(2, 0),
        c: Point2D(0, 3),
      );
      final double? scaled = angleDegrees(
        vertex: Point2D(0, 0),
        a: Point2D(20, 0),
        c: Point2D(0, 30),
      );
      expect(scaled, closeTo(base!, 1e-9));
    });

    test('REGRESSION: independent per-axis normalization shears the angle '
        '(the origin project bug this type exists to prevent)', () {
      // A bent elbow in pixel space on 1280x720 video. Deliberately NOT
      // axis-aligned in either ray: an axis-aligned right angle (one ray
      // purely horizontal, one purely vertical) is a degenerate case for
      // this particular regression, because scaling x and y by DIFFERENT
      // constants does not change the angle between a vector that is
      // pure-x and a vector that is pure-y -- only their magnitudes
      // change, and angleDegrees is scale-invariant per axis in that one
      // special case. A real elbow bend is not axis-aligned, so it does
      // not get that accidental protection.
      final Point2D shoulderPx = Point2D(600, 150);
      final Point2D elbowPx = Point2D(640, 400);
      final Point2D wristPx = Point2D(820, 340);

      final double correctAngle = angleDegrees(
        vertex: elbowPx,
        a: shoulderPx,
        c: wristPx,
      )!;

      // The origin project's bug: normalize x by width and y by height
      // independently (x/1280, y/720), THEN compute the angle from those
      // normalized coordinates. On non-square video this shears the
      // space and the same physical bend reads as a different number.
      const double width = 1280;
      const double height = 720;
      Point2D distort(Point2D p) => Point2D(p.x / width, p.y / height);

      final double shearedAngle = angleDegrees(
        vertex: distort(elbowPx),
        a: distort(shoulderPx),
        c: distort(wristPx),
      )!;

      expect(
        shearedAngle,
        isNot(closeTo(correctAngle, 0.5)),
        reason:
            'if this ever passes, either angleDegrees has stopped being '
            'sensitive to the exact distortion that corrupted every '
            'angle in the preserved v1 pose files, or this fixture has '
            'drifted back into an axis-aligned special case -- check the '
            'fixture geometry before concluding the bug is fixed',
      );
    });
  });

  group('unitDirection', () {
    test('has unit length', () {
      final Point2D? dir = unitDirection(Point2D(0, 0), Point2D(3, 4));
      expect(dir, isNotNull);
      expect(dir!.length, closeTo(1.0, 1e-9));
    });

    test('points from `from` toward `to`', () {
      final Point2D? dir = unitDirection(Point2D(0, 0), Point2D(0, 5));
      expect(dir!.x, closeTo(0.0, 1e-9));
      expect(dir.y, closeTo(1.0, 1e-9));
    });

    test('coincident points return null', () {
      final Point2D? dir = unitDirection(Point2D(1, 1), Point2D(1, 1));
      expect(dir, isNull);
    });
  });

  group('Point2D', () {
    test('distanceTo is symmetric', () {
      final Point2D a = Point2D(1, 2);
      final Point2D b = Point2D(4, 6);
      expect(a.distanceTo(b), closeTo(b.distanceTo(a), 1e-12));
    });

    test('distanceTo matches Pythagoras for a known triangle', () {
      final Point2D a = Point2D(0, 0);
      final Point2D b = Point2D(3, 4);
      expect(a.distanceTo(b), closeTo(5.0, 1e-12));
    });
  });
}
