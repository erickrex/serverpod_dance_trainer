import 'attempt_score.dart';

/// Why a run's overall judgment is suppressed, when it is. Every reason is
/// phrased as an observation problem, never a student failing — requirement
/// 8.9 requires the cause to be attributed to observation, not the student.
enum EligibilitySuppressionReason {
  /// Weighted coverage fell below the configured floor.
  insufficientCoverage,

  /// A single required section had too long a span with no assessed or
  /// observed-but-missed events at all.
  longUnobservedSpan,
}

/// The result of the ranked-eligibility check.
final class RankedEligibility {
  const RankedEligibility.eligible() : suppressionReason = null;

  const RankedEligibility.suppressed(this.suppressionReason);

  /// Null when eligible.
  final EligibilitySuppressionReason? suppressionReason;

  bool get isEligible => suppressionReason == null;
}

/// Evaluates the coverage gate from requirement 8.9.
///
/// [coverageFloor] and [maxUnobservedSpanEvents] are scoring-configuration
/// values (design.md `ScoringConfiguration`), not constants of this
/// function — they are tuned against recorded device trials and then
/// frozen under an immutable scoring version (requirement 8.10). This
/// function only applies whatever values that frozen configuration holds.
///
/// [longestUnobservedSpanEvents] is the longest run of consecutive
/// reference events, in event order, that were NOT assessed and NOT
/// observed-but-missed (i.e. purely [EventAssessment.unassessed]) —
/// computed by the caller from the same ordered event list the score was
/// aggregated from.
RankedEligibility evaluateRankedEligibility({
  required AttemptScore score,
  required double coverageFloor,
  required int longestUnobservedSpanEvents,
  required int maxUnobservedSpanEvents,
}) {
  if (!coverageFloor.isFinite ||
      coverageFloor < 0 ||
      coverageFloor > 1 ||
      !score.weightedCoverage.isFinite ||
      score.weightedCoverage < 0 ||
      score.weightedCoverage > 1 ||
      longestUnobservedSpanEvents < 0 ||
      maxUnobservedSpanEvents < 0) {
    throw ArgumentError('Invalid coverage or unobserved span.');
  }
  if (score.weightedCoverage < coverageFloor) {
    return const RankedEligibility.suppressed(
      EligibilitySuppressionReason.insufficientCoverage,
    );
  }
  if (longestUnobservedSpanEvents > maxUnobservedSpanEvents) {
    return const RankedEligibility.suppressed(
      EligibilitySuppressionReason.longUnobservedSpan,
    );
  }
  return const RankedEligibility.eligible();
}
