import 'package:dance_domain/dance_domain.dart';
import 'package:test/test.dart';

AttemptScore _scoreWithCoverage(double coverage) => AttemptScore(
  totalScore: 5000,
  weightedCoverage: coverage,
  assessedCount: 1,
  observedButMissedCount: 0,
  unassessedCount: 0,
);

void main() {
  group('evaluateRankedEligibility', () {
    test('eligible when coverage is at or above the floor', () {
      final RankedEligibility result = evaluateRankedEligibility(
        score: _scoreWithCoverage(0.85),
        coverageFloor: 0.85,
        longestUnobservedSpanEvents: 0,
        maxUnobservedSpanEvents: 3,
      );
      expect(result.isEligible, isTrue);
      expect(result.suppressionReason, isNull);
    });

    test('suppressed for insufficient coverage when just below the floor', () {
      final RankedEligibility result = evaluateRankedEligibility(
        score: _scoreWithCoverage(0.8499),
        coverageFloor: 0.85,
        longestUnobservedSpanEvents: 0,
        maxUnobservedSpanEvents: 3,
      );
      expect(result.isEligible, isFalse);
      expect(
        result.suppressionReason,
        EligibilitySuppressionReason.insufficientCoverage,
      );
    });

    test('suppressed for a long unobserved span even with full coverage', () {
      final RankedEligibility result = evaluateRankedEligibility(
        score: _scoreWithCoverage(1.0),
        coverageFloor: 0.85,
        longestUnobservedSpanEvents: 10,
        maxUnobservedSpanEvents: 3,
      );
      expect(result.isEligible, isFalse);
      expect(
        result.suppressionReason,
        EligibilitySuppressionReason.longUnobservedSpan,
      );
    });

    test('coverage check takes precedence when both conditions fail', () {
      final RankedEligibility result = evaluateRankedEligibility(
        score: _scoreWithCoverage(0.5),
        coverageFloor: 0.85,
        longestUnobservedSpanEvents: 10,
        maxUnobservedSpanEvents: 3,
      );
      expect(
        result.suppressionReason,
        EligibilitySuppressionReason.insufficientCoverage,
      );
    });

    test(
      'every suppression reason is phrased as an observation problem, not '
      'a student failing (requirement 8.9) -- this test exists so a future '
      'edit adding a new reason has to confront that constraint explicitly',
      () {
        for (final EligibilitySuppressionReason reason
            in EligibilitySuppressionReason.values) {
          const List<String> studentBlamingWords = [
            'fail',
            'bad',
            'wrong',
            'poor',
            'incorrect',
          ];
          final String name = reason.name.toLowerCase();
          for (final String word in studentBlamingWords) {
            expect(
              name.contains(word),
              isFalse,
              reason:
                  'enum value "${reason.name}" reads as blaming the '
                  'student rather than the observation quality',
            );
          }
        }
      },
    );
  });
}
