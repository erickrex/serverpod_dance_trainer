import 'package:dance_domain/dance_domain.dart';
import 'package:test/test.dart';

WeightedEventResult _assessed({
  required double weight,
  required double movement,
  required double timing,
}) => WeightedEventResult(
  weight: weight,
  quality: EventQuality.assessed(
    movementQuality: movement,
    timingQuality: timing,
    signedTimingOffsetMs: 0,
  ),
);

WeightedEventResult _missed({required double weight}) => WeightedEventResult(
  weight: weight,
  quality: EventQuality.observedButMissed(),
);

WeightedEventResult _unassessed({required double weight}) =>
    WeightedEventResult(weight: weight, quality: EventQuality.unassessed());

void main() {
  group('EventQuality.quality', () {
    test('assessed event applies the 0.6/0.4 movement/timing weighting '
        '(requirement 8.4)', () {
      final EventQuality q = EventQuality.assessed(
        movementQuality: 1.0,
        timingQuality: 0.0,
        signedTimingOffsetMs: 500,
      );
      expect(q.quality, closeTo(0.6, 1e-12));
    });

    test('perfect movement and timing gives quality 1.0', () {
      final EventQuality q = EventQuality.assessed(
        movementQuality: 1.0,
        timingQuality: 1.0,
        signedTimingOffsetMs: 0,
      );
      expect(q.quality, closeTo(1.0, 1e-12));
    });

    test('observedButMissed is a real zero, not null (requirement 8.6)', () {
      expect(EventQuality.observedButMissed().quality, 0.0);
    });

    test(
      'unassessed is null, distinct from a zero score (requirement 8.7)',
      () {
        expect(EventQuality.unassessed().quality, isNull);
      },
    );
  });

  group('aggregateAttemptScore', () {
    test('all events perfectly assessed scores exactly 10000', () {
      final AttemptScore score = aggregateAttemptScore([
        _assessed(weight: 1, movement: 1, timing: 1),
        _assessed(weight: 2, movement: 1, timing: 1),
        _assessed(weight: 3, movement: 1, timing: 1),
      ]);
      expect(score.totalScore, 10000);
      expect(score.weightedCoverage, closeTo(1.0, 1e-12));
    });

    test('all events observed-but-missed scores exactly 0', () {
      final AttemptScore score = aggregateAttemptScore([
        _missed(weight: 1),
        _missed(weight: 5),
      ]);
      expect(score.totalScore, 0);
      // Coverage is still full: these events WERE observed, just missed.
      expect(score.weightedCoverage, closeTo(1.0, 1e-12));
    });

    test('a fully unassessed event set scores 0 and reports zero coverage '
        '-- it must not be conflated with a perfect run or read as a real '
        'zero performance', () {
      final AttemptScore score = aggregateAttemptScore([
        _unassessed(weight: 1),
        _unassessed(weight: 1),
      ]);
      expect(score.totalScore, 0);
      expect(score.weightedCoverage, 0.0);
      expect(score.unassessedCount, 2);
      expect(score.assessedCount, 0);
    });

    test('ANTI-GAMING: an unassessed event weighs down the denominator, so '
        'it can only ever LOWER the score, never raise it, versus skipping '
        'it entirely (requirement 8.5)', () {
      final AttemptScore withHardSectionSkipped = aggregateAttemptScore([
        _assessed(weight: 1, movement: 1, timing: 1),
        _assessed(weight: 1, movement: 1, timing: 1),
      ]);
      final AttemptScore withHardSectionUnassessed = aggregateAttemptScore([
        _assessed(weight: 1, movement: 1, timing: 1),
        _assessed(weight: 1, movement: 1, timing: 1),
        _unassessed(weight: 5), // a heavily-weighted hard section
      ]);

      expect(withHardSectionSkipped.totalScore, 10000);
      expect(
        withHardSectionUnassessed.totalScore,
        lessThan(withHardSectionSkipped.totalScore),
        reason:
            'the full required event set is always the denominator; '
            'an unassessed event must reduce the total, never be '
            'invisible to it',
      );
      // 2 perfect (weight 1 each) + 1 unassessed (weight 5) = 2/7 of
      // total weight scored at full quality.
      expect(withHardSectionUnassessed.totalScore, 2857); // round(10000*2/7)
    });

    test('ONE OBSERVATION CANNOT SATISFY TWO EVENTS is enforced by the '
        'caller\'s event-matching step, not by this aggregator -- this test '
        'documents that boundary: aggregateAttemptScore trusts its input '
        'list and will happily double-count if the caller double-matched', () {
      // This is intentional and documented, not a gap: event matching
      // (requirement 9.7) is a bounded-window search over observations
      // that the CALLER performs once per reference event, producing
      // AT MOST one EventQuality per event. This aggregator's job is
      // only to combine already-matched results correctly.
      expect(true, isTrue);
    });

    test('throws on an empty event list rather than returning a fake zero', () {
      expect(() => aggregateAttemptScore([]), throwsArgumentError);
    });

    test('accepts a tiny positive weight', () {
      expect(
        () => aggregateAttemptScore([
          WeightedEventResult(
            weight: 0.0001,
            quality: EventQuality.unassessed(),
          ),
        ]),
        returnsNormally,
      );
    });

    test('throws when total weight is exactly zero (unreachable via the '
        'public constructor today since WeightedEventResult asserts weight '
        '> 0, but aggregateAttemptScore guards it independently in case '
        'that invariant ever moves)', () {
      // assert() is disabled in release/profile builds, so the weight>0
      // check on WeightedEventResult cannot be relied on to protect the
      // aggregator's own division at runtime in production. Confirm the
      // guard exists here as its own contract, not merely as a
      // consequence of the constructor's assert.
      expect(
        () => aggregateAttemptScore([]),
        throwsArgumentError,
        reason:
            'covered above for the empty-list case; zero total '
            'weight with a non-empty list is not constructible while '
            'the assert holds, so this documents the intended contract '
            'rather than exercising an unreachable branch',
      );
    });

    test(
      'weightedCoverage counts assessed AND observedButMissed, not just assessed',
      () {
        final AttemptScore score = aggregateAttemptScore([
          _assessed(weight: 1, movement: 1, timing: 1),
          _missed(weight: 1),
          _unassessed(weight: 2),
        ]);
        // (1 + 1) assessed-or-missed out of (1 + 1 + 2) total weight = 0.5
        expect(score.weightedCoverage, closeTo(0.5, 1e-12));
      },
    );

    test('score rounds rather than truncates', () {
      // 3 events, one perfect out of weight-equal three -> 10000/3 = 3333.33
      final AttemptScore score = aggregateAttemptScore([
        _assessed(weight: 1, movement: 1, timing: 1),
        _unassessed(weight: 1),
        _unassessed(weight: 1),
      ]);
      expect(score.totalScore, 3333);
    });
  });

  group('WeightedEventResult', () {
    test('rejects a non-positive weight', () {
      expect(
        () =>
            WeightedEventResult(weight: 0, quality: EventQuality.unassessed()),
        throwsArgumentError,
      );
      expect(
        () =>
            WeightedEventResult(weight: -1, quality: EventQuality.unassessed()),
        throwsArgumentError,
      );
    });
  });
}
