import 'dart:math' as math;
import '../pose/geometry.dart';
import 'attempt_score.dart';
import 'normalization.dart';

/// A versioned target pose. Reference features contain only the measurements
/// the annotated movement needs; missing required measurements are unassessed.
final class ReferenceEvent {
  ReferenceEvent({
    required this.id,
    required this.sectionId,
    required this.targetContentTime,
    required this.weight,
    required this.matchWindow,
    required this.timingFullCreditWindow,
    required this.timingZeroCreditWindow,
    required List<String> requiredLandmarks,
    required this.referenceFeatures,
    this.positionTolerance = 0.75,
    this.directionToleranceDegrees = 75,
  }) : requiredLandmarks = List.unmodifiable(requiredLandmarks) {
    if (id.isEmpty ||
        sectionId.isEmpty ||
        targetContentTime.isNegative ||
        !weight.isFinite ||
        weight <= 0 ||
        matchWindow <= Duration.zero ||
        timingFullCreditWindow.isNegative ||
        timingZeroCreditWindow <= timingFullCreditWindow ||
        timingZeroCreditWindow > matchWindow ||
        !positionTolerance.isFinite ||
        positionTolerance <= 0 ||
        !directionToleranceDegrees.isFinite ||
        directionToleranceDegrees <= 0) {
      throw ArgumentError('Invalid reference event or timing windows.');
    }
  }
  final String id;
  final String sectionId;
  final Duration targetContentTime;
  final double weight;
  final Duration matchWindow;
  final Duration timingFullCreditWindow;
  final Duration timingZeroCreditWindow;
  final List<String> requiredLandmarks;
  final NormalizedFeatures referenceFeatures;
  final double positionTolerance;
  final double directionToleranceDegrees;
}

final class MatchableObservation {
  MatchableObservation({
    required this.contentTime,
    required this.features,
    required Set<String> observedLandmarks,
  }) : observedLandmarks = Set.unmodifiable(observedLandmarks) {
    if (contentTime.isNegative) {
      throw ArgumentError('Negative observation time.');
    }
  }
  final Duration contentTime;
  final NormalizedFeatures? features;
  final Set<String> observedLandmarks;
}

void _positive(double value, String name) {
  if (!value.isFinite || value <= 0) throw ArgumentError.value(value, name);
}

/// Returns null for non-finite measurements rather than allowing NaN.clamp
/// to turn corrupt evidence into a perfect match.
double? jointAngleSimilarity({
  required Map<String, double?> reference,
  required Map<String, double?> observed,
  required double toleranceDegrees,
}) {
  _positive(toleranceDegrees, 'toleranceDegrees');
  final scores = <double>[];
  for (final entry in reference.entries) {
    final a = entry.value;
    final b = observed[entry.key];
    if (a == null || b == null) continue;
    if (!a.isFinite || !b.isFinite) return null;
    scores.add((1 - (a - b).abs() / toleranceDegrees).clamp(0.0, 1.0));
  }
  return scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length;
}

double timingSimilarity({
  required Duration signedOffset,
  required Duration fullCreditWindow,
  required Duration zeroCreditWindow,
}) {
  if (fullCreditWindow.isNegative || zeroCreditWindow <= fullCreditWindow) {
    throw ArgumentError('Timing windows must be ordered and nonnegative.');
  }
  final offset = signedOffset.abs();
  if (offset <= fullCreditWindow) return 1;
  if (offset >= zeroCreditWindow) return 0;
  return 1 -
      (offset - fullCreditWindow).inMicroseconds /
          (zeroCreditWindow - fullCreditWindow).inMicroseconds;
}

/// The least-matching required feature limits the movement score. This prevents
/// unchanged legs from masking an arm pointing in the opposite direction.
double? movementSimilarity(
  ReferenceEvent event,
  NormalizedFeatures observed,
  double angleTolerance,
) {
  _positive(angleTolerance, 'movementToleranceDegrees');
  final scores = <double>[];
  for (final entry in event.referenceFeatures.jointAngles.entries) {
    final a = entry.value;
    if (a == null) continue;
    final b = observed.jointAngles[entry.key];
    if (b == null || !a.isFinite || !b.isFinite) return null;
    scores.add((1 - (a - b).abs() / angleTolerance).clamp(0.0, 1.0));
  }
  for (final entry in event.referenceFeatures.limbDirections.entries) {
    final a = entry.value;
    if (a == null) continue;
    final b = observed.limbDirections[entry.key];
    if (b == null || a.length < 1e-9 || b.length < 1e-9) return null;
    final angle =
        math.acos((a.dot(b) / (a.length * b.length)).clamp(-1.0, 1.0)) *
        180 /
        math.pi;
    if (!angle.isFinite) return null;
    scores.add((1 - angle / event.directionToleranceDegrees).clamp(0.0, 1.0));
  }
  for (final entry in event.referenceFeatures.scaledPositions.entries) {
    final Point2D? a = entry.value;
    if (a == null) continue;
    final b = observed.scaledPositions[entry.key];
    if (b == null) return null;
    scores.add((1 - a.distanceTo(b) / event.positionTolerance).clamp(0.0, 1.0));
  }
  return scores.isEmpty ? null : scores.reduce(math.min);
}

int? _closest(
  ReferenceEvent event,
  List<MatchableObservation> observations,
  Set<int> used,
) {
  int? best;
  var offset = event.matchWindow.inMicroseconds + 1;
  for (var i = 0; i < observations.length; i++) {
    final candidate = observations[i];
    if (used.contains(i) ||
        candidate.features == null ||
        !event.requiredLandmarks.every(candidate.observedLandmarks.contains)) {
      continue;
    }
    final delta = (candidate.contentTime - event.targetContentTime)
        .inMicroseconds
        .abs();
    if (delta <= event.matchWindow.inMicroseconds &&
        (delta < offset ||
            (delta == offset &&
                best != null &&
                candidate.contentTime < observations[best].contentTime))) {
      best = i;
      offset = delta;
    }
  }
  return best;
}

EventQuality _judge(
  ReferenceEvent event,
  MatchableObservation? observation,
  double tolerance,
) {
  if (observation == null) return EventQuality.unassessed();
  final movement = movementSimilarity(event, observation.features!, tolerance);
  if (movement == null) return EventQuality.unassessed();
  if (movement <= 0) return EventQuality.observedButMissed();
  final offset = observation.contentTime - event.targetContentTime;
  return EventQuality.assessed(
    movementQuality: movement,
    timingQuality: timingSimilarity(
      signedOffset: offset,
      fullCreditWindow: event.timingFullCreditWindow,
      zeroCreditWindow: event.timingZeroCreditWindow,
    ),
    signedTimingOffsetMs: offset.inMicroseconds / 1000,
  );
}

EventQuality matchReferenceEvent({
  required ReferenceEvent event,
  required List<MatchableObservation> observations,
  required double movementToleranceDegrees,
}) {
  _positive(movementToleranceDegrees, 'movementToleranceDegrees');
  final index = _closest(event, observations, {});
  return _judge(
    event,
    index == null ? null : observations[index],
    movementToleranceDegrees,
  );
}

/// Matches the full event set exactly once. Each distinct capture can satisfy
/// at most one event, even where match windows overlap.
List<WeightedEventResult> matchAttemptEvents({
  required List<ReferenceEvent> events,
  required List<MatchableObservation> observations,
  double movementToleranceDegrees = 45,
}) {
  _positive(movementToleranceDegrees, 'movementToleranceDegrees');
  if (events.map((e) => e.id).toSet().length != events.length) {
    throw ArgumentError('Duplicate reference event id.');
  }
  if (observations.map((o) => o.contentTime).toSet().length !=
      observations.length) {
    throw ArgumentError('Duplicate capture time.');
  }
  final ordered = List<ReferenceEvent>.of(events)
    ..sort((a, b) {
      final time = a.targetContentTime.compareTo(b.targetContentTime);
      return time != 0 ? time : a.id.compareTo(b.id);
    });
  final used = <int>{};
  return [
    for (final event in ordered)
      (() {
        final index = _closest(event, observations, used);
        if (index != null) used.add(index);
        return WeightedEventResult(
          weight: event.weight,
          quality: _judge(
            event,
            index == null ? null : observations[index],
            movementToleranceDegrees,
          ),
        );
      })(),
  ];
}
