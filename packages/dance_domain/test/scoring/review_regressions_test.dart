import 'package:dance_domain/dance_domain.dart';
import 'package:test/test.dart';

NormalizedFeatures features({double angle = 180, double direction = 1}) =>
    NormalizedFeatures(
      jointAngles: {'leftElbow': angle},
      limbDirections: {'leftUpperArm': Point2D(0, direction)},
      scaledPositions: {},
      bodyScale: 100,
    );
ReferenceEvent event(String id, {double direction = -1}) => ReferenceEvent(
  id: id,
  sectionId: 's',
  targetContentTime: const Duration(seconds: 1),
  weight: 1,
  matchWindow: const Duration(milliseconds: 300),
  timingFullCreditWindow: const Duration(milliseconds: 80),
  timingZeroCreditWindow: const Duration(milliseconds: 250),
  requiredLandmarks: ['leftShoulder', 'leftElbow', 'leftWrist'],
  referenceFeatures: features(direction: direction),
);
MatchableObservation observation({double direction = 1}) =>
    MatchableObservation(
      contentTime: const Duration(seconds: 1),
      features: features(direction: direction),
      observedLandmarks: {'leftShoulder', 'leftElbow', 'leftWrist'},
    );
void main() {
  test('arms down cannot satisfy an arms-up event with straight elbows', () {
    final q = matchReferenceEvent(
      event: event('arm'),
      observations: [observation()],
      movementToleranceDegrees: 45,
    );
    expect(q.assessment, EventAssessment.observedButMissed);
    expect(
      aggregateAttemptScore([
        WeightedEventResult(weight: 1, quality: q),
      ]).totalScore,
      0,
    );
  });
  test('one capture cannot satisfy overlapping events', () {
    final results = matchAttemptEvents(
      events: [event('a'), event('b')],
      observations: [observation(direction: -1)],
    );
    final score = aggregateAttemptScore(results);
    expect(score.totalScore, 5000);
    expect(score.weightedCoverage, 0.5);
  });
  test('duplicate capture times are rejected', () {
    expect(
      () => matchAttemptEvents(
        events: [event('a')],
        observations: [observation(), observation()],
      ),
      throwsArgumentError,
    );
  });
  test(
    'all partially missing coordinates and nonfinite values are rejected',
    () {
      for (final xy in [
        (null, 1.0),
        (1.0, null),
        (double.nan, 1.0),
        (1.0, double.infinity),
      ]) {
        expect(
          () => Landmark(
            x: xy.$1,
            y: xy.$2,
            confidence: 0.9,
            validity: LandmarkValidity.observed,
          ),
          throwsArgumentError,
        );
      }
    },
  );
  test(
    'invalid qualities and weights cannot escape through public constructors',
    () {
      for (final value in [-1.0, 2.0, double.nan, double.infinity]) {
        expect(
          () => EventQuality.assessed(
            movementQuality: value,
            timingQuality: 1,
            signedTimingOffsetMs: 0,
          ),
          throwsArgumentError,
        );
      }
      for (final weight in [0.0, -1.0, double.nan, double.infinity]) {
        expect(
          () => WeightedEventResult(
            weight: weight,
            quality: EventQuality.unassessed(),
          ),
          throwsArgumentError,
        );
      }
    },
  );
  test(
    'nonfinite angles are unmeasurable and invalid tolerance is rejected',
    () {
      expect(
        jointAngleSimilarity(
          reference: {'a': 90},
          observed: {'a': double.nan},
          toleranceDegrees: 30,
        ),
        isNull,
      );
      expect(
        () => jointAngleSimilarity(
          reference: {'a': 90},
          observed: {'a': 90},
          toleranceDegrees: 0,
        ),
        throwsArgumentError,
      );
    },
  );
  test('missing required feature does not improve a movement score', () {
    final missing = MatchableObservation(
      contentTime: const Duration(seconds: 1),
      observedLandmarks: kLandmarkNames.toSet(),
      features: const NormalizedFeatures(
        jointAngles: {'leftElbow': 180},
        limbDirections: {},
        scaledPositions: {},
        bodyScale: 100,
      ),
    );
    expect(
      matchReferenceEvent(
        event: event('a'),
        observations: [missing],
        movementToleranceDegrees: 45,
      ).assessment,
      EventAssessment.unassessed,
    );
  });
}
