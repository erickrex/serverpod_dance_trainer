import 'package:dance_domain/dance_domain.dart';
import 'package:test/test.dart';

NormalizedFeatures _features(Map<String, double?> angles) => NormalizedFeatures(
  jointAngles: angles,
  limbDirections: const {},
  scaledPositions: const {},
  bodyScale: 300.0,
);

ReferenceEvent _event({
  Duration matchWindow = const Duration(milliseconds: 300),
  Duration fullCredit = const Duration(milliseconds: 80),
  Duration zeroCredit = const Duration(milliseconds: 250),
  Map<String, double?>? referenceAngles,
}) => ReferenceEvent(
  id: 'evt-1',
  sectionId: 'section-1',
  targetContentTime: const Duration(seconds: 10),
  weight: 1.0,
  matchWindow: matchWindow,
  timingFullCreditWindow: fullCredit,
  timingZeroCreditWindow: zeroCredit,
  requiredLandmarks: const ['leftShoulder', 'leftElbow', 'leftWrist'],
  referenceFeatures: _features(referenceAngles ?? {'leftElbow': 90.0}),
);

MatchableObservation _observation({
  required Duration contentTime,
  Map<String, double?>? angles,
  Set<String>? observedLandmarks,
}) => MatchableObservation(
  contentTime: contentTime,
  features: angles == null ? null : _features(angles),
  observedLandmarks:
      observedLandmarks ?? const {'leftShoulder', 'leftElbow', 'leftWrist'},
);

void main() {
  group('jointAngleSimilarity', () {
    test('identical angles score 1.0', () {
      final double? score = jointAngleSimilarity(
        reference: {'leftElbow': 90.0},
        observed: {'leftElbow': 90.0},
        toleranceDegrees: 30.0,
      );
      expect(score, closeTo(1.0, 1e-9));
    });

    test('a difference at exactly the tolerance scores 0.0', () {
      final double? score = jointAngleSimilarity(
        reference: {'leftElbow': 90.0},
        observed: {'leftElbow': 120.0},
        toleranceDegrees: 30.0,
      );
      expect(score, closeTo(0.0, 1e-9));
    });

    test('a difference beyond the tolerance clamps to 0.0, not negative', () {
      final double? score = jointAngleSimilarity(
        reference: {'leftElbow': 90.0},
        observed: {'leftElbow': 200.0},
        toleranceDegrees: 30.0,
      );
      expect(score, 0.0);
    });

    test('is smooth: a small miss scores much higher than a large one', () {
      final double small = jointAngleSimilarity(
        reference: {'leftElbow': 90.0},
        observed: {'leftElbow': 95.0},
        toleranceDegrees: 30.0,
      )!;
      final double large = jointAngleSimilarity(
        reference: {'leftElbow': 90.0},
        observed: {'leftElbow': 115.0},
        toleranceDegrees: 30.0,
      )!;
      expect(small, greaterThan(large));
      expect(small, greaterThan(0.5));
      expect(large, lessThan(0.5));
    });

    test('an angle unmeasurable in the reference OR observation is skipped, '
        'not scored as a mismatch', () {
      final double? score = jointAngleSimilarity(
        reference: {'leftElbow': 90.0, 'rightElbow': null},
        observed: {'leftElbow': 90.0, 'rightElbow': 40.0},
        toleranceDegrees: 30.0,
      );
      // rightElbow is skipped (reference null); only leftElbow (perfect
      // match) counts, so the average should be a clean 1.0, not
      // dragged down by a "mismatch" that was never real evidence.
      expect(score, closeTo(1.0, 1e-9));
    });

    test('returns null when there is no comparable angle at all', () {
      final double? score = jointAngleSimilarity(
        reference: {'leftElbow': null},
        observed: {'leftElbow': 90.0},
        toleranceDegrees: 30.0,
      );
      expect(
        score,
        isNull,
        reason:
            '"nothing to compare" must be distinguishable from '
            '"compared and found dissimilar" -- collapsing both into 0.0 '
            'would make an unmeasurable angle look like a real miss',
      );
    });
  });

  group('timingSimilarity', () {
    test('full credit inside the full-credit window, either direction', () {
      expect(
        timingSimilarity(
          signedOffset: const Duration(milliseconds: 50),
          fullCreditWindow: const Duration(milliseconds: 80),
          zeroCreditWindow: const Duration(milliseconds: 250),
        ),
        1.0,
      );
      expect(
        timingSimilarity(
          signedOffset: const Duration(milliseconds: -50),
          fullCreditWindow: const Duration(milliseconds: 80),
          zeroCreditWindow: const Duration(milliseconds: 250),
        ),
        1.0,
      );
    });

    test('zero credit at or beyond the zero-credit window', () {
      expect(
        timingSimilarity(
          signedOffset: const Duration(milliseconds: 250),
          fullCreditWindow: const Duration(milliseconds: 80),
          zeroCreditWindow: const Duration(milliseconds: 250),
        ),
        0.0,
      );
      expect(
        timingSimilarity(
          signedOffset: const Duration(milliseconds: 400),
          fullCreditWindow: const Duration(milliseconds: 80),
          zeroCreditWindow: const Duration(milliseconds: 250),
        ),
        0.0,
      );
    });

    test('decays linearly between the two windows', () {
      final double midpoint = timingSimilarity(
        signedOffset: const Duration(milliseconds: 165), // halfway 80->250
        fullCreditWindow: const Duration(milliseconds: 80),
        zeroCreditWindow: const Duration(milliseconds: 250),
      );
      expect(midpoint, closeTo(0.5, 0.02));
    });
  });

  group('matchReferenceEvent', () {
    test('unassessed when no observation falls inside the match window', () {
      final ReferenceEvent event = _event();
      final EventQuality result = matchReferenceEvent(
        event: event,
        observations: [
          _observation(contentTime: const Duration(seconds: 20)), // far away
        ],
        movementToleranceDegrees: 30.0,
      );
      expect(result.assessment, EventAssessment.unassessed);
    });

    test('unassessed when the only in-window observation is missing a '
        'required landmark -- this is a tracking gap, not a miss', () {
      final ReferenceEvent event = _event();
      final EventQuality result = matchReferenceEvent(
        event: event,
        observations: [
          _observation(
            contentTime: const Duration(seconds: 10, milliseconds: 20),
            angles: {'leftElbow': 10.0},
            observedLandmarks: {'leftShoulder'}, // missing elbow, wrist
          ),
        ],
        movementToleranceDegrees: 30.0,
      );
      expect(result.assessment, EventAssessment.unassessed);
    });

    test('assessed when a well-tracked observation falls in the window, even '
        'if the movement is completely wrong -- being trackable and being '
        'correct are different questions', () {
      final ReferenceEvent event = _event(referenceAngles: {'leftElbow': 90.0});
      final EventQuality result = matchReferenceEvent(
        event: event,
        observations: [
          _observation(
            contentTime: const Duration(seconds: 10),
            angles: {'leftElbow': 180.0}, // arm straight, not bent
          ),
        ],
        movementToleranceDegrees: 30.0,
      );
      expect(result.assessment, EventAssessment.observedButMissed);
      expect(result.quality, 0.0);
    });

    test('picks the CLOSEST-IN-TIME candidate, not the best-scoring one', () {
      final ReferenceEvent event = _event(referenceAngles: {'leftElbow': 90.0});
      final EventQuality result = matchReferenceEvent(
        event: event,
        observations: [
          // Far in time (150ms off), but a perfect angle match.
          _observation(
            contentTime: const Duration(seconds: 10, milliseconds: 150),
            angles: {'leftElbow': 90.0},
          ),
          // Close in time (10ms off), imperfect angle match.
          _observation(
            contentTime: const Duration(seconds: 10, milliseconds: 10),
            angles: {'leftElbow': 100.0},
          ),
        ],
        movementToleranceDegrees: 30.0,
      );
      // Should have matched the CLOSE one (10ms), so timing quality is
      // full credit (inside the 80ms full-credit window) even though
      // movement quality is imperfect.
      expect(result.timingQuality, closeTo(1.0, 1e-9));
      expect(result.movementQuality, lessThan(1.0));
    });

    test('signed timing offset is positive when late, negative when early', () {
      final ReferenceEvent event = _event();
      final EventQuality late = matchReferenceEvent(
        event: event,
        observations: [
          _observation(
            contentTime: const Duration(seconds: 10, milliseconds: 100),
            angles: {'leftElbow': 90.0},
          ),
        ],
        movementToleranceDegrees: 30.0,
      );
      final EventQuality early = matchReferenceEvent(
        event: event,
        observations: [
          _observation(
            contentTime: const Duration(seconds: 9, milliseconds: 900),
            angles: {'leftElbow': 90.0},
          ),
        ],
        movementToleranceDegrees: 30.0,
      );
      expect(late.signedTimingOffsetMs, greaterThan(0));
      expect(early.signedTimingOffsetMs, lessThan(0));
    });

    test('a candidate right at the edge of the match window is included; '
        'just past it is excluded (bounded window, requirement 9.5-9.6)', () {
      final ReferenceEvent event = _event(
        matchWindow: const Duration(milliseconds: 300),
      );
      final EventQuality atEdge = matchReferenceEvent(
        event: event,
        observations: [
          _observation(
            contentTime: const Duration(seconds: 10, milliseconds: 300),
            angles: {'leftElbow': 90.0},
          ),
        ],
        movementToleranceDegrees: 30.0,
      );
      final EventQuality justPast = matchReferenceEvent(
        event: event,
        observations: [
          _observation(
            contentTime: const Duration(seconds: 10, milliseconds: 301),
            angles: {'leftElbow': 90.0},
          ),
        ],
        movementToleranceDegrees: 30.0,
      );
      expect(atEdge.assessment, EventAssessment.assessed);
      expect(justPast.assessment, EventAssessment.unassessed);
    });

    test('ONE OBSERVATION CANNOT SATISFY TWO EVENTS is a caller responsibility '
        '-- documented here so the boundary is explicit: matching the SAME '
        'observation against two different events independently is legal '
        'at this function\'s level and will happily double-count', () {
      final MatchableObservation shared = _observation(
        contentTime: const Duration(seconds: 10),
        angles: {'leftElbow': 90.0},
      );
      final ReferenceEvent eventA = _event();
      final ReferenceEvent eventB = ReferenceEvent(
        id: 'evt-2',
        sectionId: 'section-1',
        targetContentTime: const Duration(seconds: 10, milliseconds: 5),
        weight: 1.0,
        matchWindow: const Duration(milliseconds: 300),
        timingFullCreditWindow: const Duration(milliseconds: 80),
        timingZeroCreditWindow: const Duration(milliseconds: 250),
        requiredLandmarks: const ['leftShoulder', 'leftElbow', 'leftWrist'],
        referenceFeatures: _features({'leftElbow': 90.0}),
      );

      final EventQuality resultA = matchReferenceEvent(
        event: eventA,
        observations: [shared],
        movementToleranceDegrees: 30.0,
      );
      final EventQuality resultB = matchReferenceEvent(
        event: eventB,
        observations: [shared],
        movementToleranceDegrees: 30.0,
      );

      // Both assessed from the SAME observation -- this is the exact
      // thing a real event-matching pipeline must prevent by construction
      // (e.g. removing a matched observation from the pool before
      // matching the next event), which this package's public API does
      // not enforce for you. See the doc comment on matchReferenceEvent.
      expect(resultA.assessment, EventAssessment.assessed);
      expect(resultB.assessment, EventAssessment.assessed);
    });
  });
}
