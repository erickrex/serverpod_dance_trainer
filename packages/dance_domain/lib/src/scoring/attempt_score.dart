/// Whether a reference event could be judged at all.
enum EventAssessment {
  /// Matched to a student observation with sufficient tracking; movement
  /// and timing quality are both meaningful.
  assessed,

  /// Clearly observed (tracking was sufficient) but the movement did not
  /// happen. This is a REAL miss and scores zero (requirement 8.6) — it
  /// must not be confused with [unassessed].
  observedButMissed,

  /// Tracking was insufficient to judge this event at all. Awards no
  /// points, but — critically — is not a "miss": it must never be
  /// presented as the student's fault (requirement 8.7, 8.9).
  unassessed,
}

/// The per-event judgment the scorer produces before aggregation.
final class EventQuality {
  EventQuality({
    required this.assessment,
    this.movementQuality,
    this.timingQuality,
    this.signedTimingOffsetMs,
  }) {
    if (assessment == EventAssessment.assessed) {
      for (final value in [movementQuality, timingQuality]) {
        if (value == null || !value.isFinite || value < 0 || value > 1) {
          throw ArgumentError(
            'Assessed qualities must be finite and in [0, 1].',
          );
        }
      }
      if (signedTimingOffsetMs == null || !signedTimingOffsetMs!.isFinite) {
        throw ArgumentError('Assessed timing offset must be finite.');
      }
    } else if (movementQuality != null ||
        timingQuality != null ||
        signedTimingOffsetMs != null) {
      throw ArgumentError(
        'Unassessed and missed events cannot carry qualities.',
      );
    }
  }

  factory EventQuality.unassessed() =>
      EventQuality(assessment: EventAssessment.unassessed);

  factory EventQuality.observedButMissed() =>
      EventQuality(assessment: EventAssessment.observedButMissed);

  factory EventQuality.assessed({
    required double movementQuality,
    required double timingQuality,
    required double signedTimingOffsetMs,
  }) => EventQuality(
    assessment: EventAssessment.assessed,
    movementQuality: movementQuality,
    timingQuality: timingQuality,
    signedTimingOffsetMs: signedTimingOffsetMs,
  );

  final EventAssessment assessment;

  /// In [0, 1]. Null unless [assessment] is [EventAssessment.assessed].
  final double? movementQuality;

  /// In [0, 1]. Null unless [assessment] is [EventAssessment.assessed].
  final double? timingQuality;

  /// Positive means late, negative means early. Retained even though the
  /// bounded event-matching window already limited what could match, so a
  /// diagnostic can still say "you were consistently N ms late" rather than
  /// only "your timing quality was low" (requirement 9.5, design.md).
  final double? signedTimingOffsetMs;

  /// The combined quality contribution for scoring, per requirement 8.4:
  /// `eventQuality = 0.6 * movementQuality + 0.4 * timingQuality`.
  ///
  /// Zero for [EventAssessment.observedButMissed] (requirement 8.6): a
  /// clearly observed but unperformed movement is a real miss.
  ///
  /// Null — not zero — for [EventAssessment.unassessed] (requirement 8.7):
  /// an event with insufficient tracking contributes nothing to the score,
  /// but is excluded from the denominator's numerator contribution
  /// differently than a real miss. See [totalScore] for how the two cases
  /// are actually combined; the distinction exists so a caller computing
  /// coverage can tell "we judged this and it failed" from "we could not
  /// judge this" without re-deriving it from quality alone.
  double? get quality => switch (assessment) {
    EventAssessment.assessed => 0.6 * movementQuality! + 0.4 * timingQuality!,
    EventAssessment.observedButMissed => 0.0,
    EventAssessment.unassessed => null,
  };
}

/// One reference event's weight and computed quality, ready for aggregation.
final class WeightedEventResult {
  WeightedEventResult({required this.weight, required this.quality}) {
    if (!weight.isFinite || weight <= 0) {
      throw ArgumentError.value(
        weight,
        'weight',
        'Must be finite and positive.',
      );
    }
  }

  final double weight;
  final EventQuality quality;
}

/// The aggregate result of scoring one attempt against one reference bundle.
final class AttemptScore {
  const AttemptScore({
    required this.totalScore,
    required this.weightedCoverage,
    required this.assessedCount,
    required this.observedButMissedCount,
    required this.unassessedCount,
  });

  /// 0 to 10000, per requirement 8.4.
  final int totalScore;

  /// Fraction, in [0, 1], of total reference event WEIGHT that was
  /// [EventAssessment.assessed] or [EventAssessment.observedButMissed] (i.e.
  /// NOT [EventAssessment.unassessed]). This is the coverage figure that
  /// must accompany every score (requirement 8.8) and gate ranked
  /// eligibility (requirement 8.9) — deliberately weighted by event weight,
  /// not a plain event count, so a handful of heavily-weighted unassessed
  /// events cannot hide behind many lightly-weighted assessed ones.
  final double weightedCoverage;

  final int assessedCount;
  final int observedButMissedCount;
  final int unassessedCount;
}

/// Aggregates per-event results into a total score, per requirement 8.4-8.8.
///
/// `eventQuality = 0.6 * movementQuality + 0.4 * timingQuality` for an
/// assessed event (computed by [EventQuality.quality] above).
///
/// `totalScore = round(10000 * sum(eventWeight * eventQuality) /
/// sum(allReferenceEventWeights))`
///
/// The denominator is EVERY reference event's weight, assessed or not
/// (requirement 8.5) — this is the mechanism that stops hiding a hard
/// section from raising a score: an unassessed event contributes zero to
/// the numerator but its weight still counts on the bottom, so skipping
/// it can only ever lower the total, never help it.
///
/// Throws [ArgumentError] on an empty list or non-positive total weight;
/// a routine with no reference events is a content bug, not a valid score
/// of zero.
AttemptScore aggregateAttemptScore(List<WeightedEventResult> results) {
  if (results.isEmpty) {
    throw ArgumentError('cannot score an attempt with no reference events');
  }

  double totalWeight = 0.0;
  double weightedQualitySum = 0.0;
  double assessedOrMissedWeight = 0.0;
  int assessed = 0;
  int observedButMissed = 0;
  int unassessed = 0;

  for (final WeightedEventResult result in results) {
    totalWeight += result.weight;
    final double? quality = result.quality.quality;
    if (quality != null) {
      weightedQualitySum += result.weight * quality;
      assessedOrMissedWeight += result.weight;
    }
    switch (result.quality.assessment) {
      case EventAssessment.assessed:
        assessed++;
      case EventAssessment.observedButMissed:
        observedButMissed++;
      case EventAssessment.unassessed:
        unassessed++;
    }
  }

  if (!totalWeight.isFinite ||
      !weightedQualitySum.isFinite ||
      totalWeight <= 0) {
    throw ArgumentError('sum of reference event weights must be positive');
  }

  final int totalScore = (10000 * weightedQualitySum / totalWeight).round();

  return AttemptScore(
    totalScore: totalScore,
    weightedCoverage: assessedOrMissedWeight / totalWeight,
    assessedCount: assessed,
    observedButMissedCount: observedButMissed,
    unassessedCount: unassessed,
  );
}
