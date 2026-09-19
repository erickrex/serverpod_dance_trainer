import 'package:dance_domain/dance_domain.dart';
import 'package:test/test.dart';

Map<String, Landmark> _allObserved({double confidence = 0.9}) => {
  for (final String name in kLandmarkNames)
    name: Landmark(
      x: 0.5,
      y: 0.5,
      confidence: confidence,
      validity: LandmarkValidity.observed,
    ),
};

void main() {
  group('Landmark', () {
    test('absent factory produces null coordinates and zero confidence', () {
      final Landmark landmark = Landmark.absent();
      expect(landmark.x, isNull);
      expect(landmark.y, isNull);
      expect(landmark.confidence, 0.0);
      expect(landmark.validity, LandmarkValidity.absent);
      expect(landmark.isUsable, isFalse);
    });

    test('construction asserts x/y are null iff validity is absent '
        '(the exact bug class this type exists to prevent)', () {
      expect(
        () => Landmark(
          x: 0.0,
          y: 0.0,
          confidence: 0.0,
          validity: LandmarkValidity.absent,
        ),
        throwsArgumentError,
        reason:
            'a missing landmark must never be encoded as x:0, y:0 -- '
            'that is indistinguishable from a real observation at the '
            'origin, which is exactly the origin project\'s bug',
      );
    });

    test('construction asserts confidence is in [0, 1]', () {
      expect(
        () => Landmark(
          x: 0,
          y: 0,
          confidence: 1.5,
          validity: LandmarkValidity.observed,
        ),
        throwsArgumentError,
      );
    });

    test('lowConfidence landmark is not usable even with coordinates', () {
      final Landmark landmark = Landmark(
        x: 0.4,
        y: 0.6,
        confidence: 0.2,
        validity: LandmarkValidity.lowConfidence,
      );
      expect(landmark.isUsable, isFalse);
    });

    test('equality is structural', () {
      final Landmark a = Landmark(
        x: 0.1,
        y: 0.2,
        confidence: 0.9,
        validity: LandmarkValidity.observed,
      );
      final Landmark b = Landmark(
        x: 0.1,
        y: 0.2,
        confidence: 0.9,
        validity: LandmarkValidity.observed,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('LandmarkFrame', () {
    test('rejects construction missing a required landmark', () {
      final Map<String, Landmark> incomplete = _allObserved()
        ..remove('leftAnkle');
      expect(
        () => LandmarkFrame(incomplete),
        throwsArgumentError,
        reason:
            'a landmark must be explicitly Landmark.absent(), never '
            'silently omitted from the map',
      );
    });

    test('accepts a frame with every landmark explicitly absent', () {
      final Map<String, Landmark> allAbsent = {
        for (final String name in kLandmarkNames) name: Landmark.absent(),
      };
      final LandmarkFrame frame = LandmarkFrame(allAbsent);
      expect(frame.hasCoreCoverage, isFalse);
    });

    test('operator[] throws on an unknown landmark name', () {
      final LandmarkFrame frame = LandmarkFrame(_allObserved());
      expect(() => frame['notAKnownLandmark'], throwsArgumentError);
    });

    test('hasCoreCoverage is true when all core landmarks are observed', () {
      final LandmarkFrame frame = LandmarkFrame(_allObserved());
      expect(frame.hasCoreCoverage, isTrue);
    });

    test('hasCoreCoverage is false when a CORE landmark is missing, even if '
        'all 17 minus that one are observed', () {
      final Map<String, Landmark> landmarks = _allObserved();
      landmarks['leftHip'] = Landmark.absent();
      final LandmarkFrame frame = LandmarkFrame(landmarks);
      expect(frame.hasCoreCoverage, isFalse);
    });

    test('hasCoreCoverage is true even when a NON-core (face) landmark is '
        'missing -- coverage is judged on the 8 core landmarks, not all 17 '
        '(requirement 8.8; measured ~94% vs ~59% on preserved content)', () {
      final Map<String, Landmark> landmarks = _allObserved();
      landmarks['nose'] = Landmark.absent();
      landmarks['leftEye'] = Landmark.absent();
      landmarks['rightEar'] = Landmark.absent();
      final LandmarkFrame frame = LandmarkFrame(landmarks);
      expect(frame.hasCoreCoverage, isTrue);
    });

    test('allObserved checks exactly the requested subset', () {
      final Map<String, Landmark> landmarks = _allObserved();
      landmarks['leftWrist'] = Landmark.absent();
      final LandmarkFrame frame = LandmarkFrame(landmarks);
      expect(frame.allObserved(['leftShoulder', 'rightShoulder']), isTrue);
      expect(frame.allObserved(['leftWrist', 'rightWrist']), isFalse);
    });
  });
}
