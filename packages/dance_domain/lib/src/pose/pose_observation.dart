import 'landmark.dart';

/// One inference result at one moment in time.
///
/// The timing fields are why this type exists as more than a bare
/// [LandmarkFrame]: requirement 5.7 forbids deriving a dance timestamp from
/// processed-frame count or inference completion time, and requirement 9.1
/// requires mapping camera capture time through an anchored playback clock.
/// [captureTimestamp] is the ONLY input to that mapping; [contentTimestamp]
/// is its output, filled in later once a [PlaybackClock] (in
/// `dance_trainer_flutter`, not this package) has resolved it.
final class PoseObservation {
  PoseObservation({
    required this.captureTimestamp,
    required this.sequence,
    required this.segmentId,
    required this.landmarks,
    required this.personDetected,
    required this.modelVersion,
    this.contentTimestamp,
  });

  /// Monotonic device clock time when the frame was captured. Never derived
  /// from frame count or inference latency (requirement 5.7).
  final Duration captureTimestamp;

  /// Media content time this observation maps to, once resolved by a
  /// playback clock anchor. Null until resolved, and deliberately mutable
  /// state lives outside this type — [PoseObservation] itself is immutable.
  final Duration? contentTimestamp;

  /// Monotonically increasing per-run sequence number, used for ordering and
  /// for the idempotent chunk upload (requirement 7.3).
  final int sequence;

  /// Identifies the playback segment this observation belongs to. A pause,
  /// seek, loop boundary or rate change starts a new segment (requirement
  /// 9.4); observations from an old segment must never be matched against
  /// events in a new one.
  final int segmentId;

  final LandmarkFrame landmarks;

  /// Whether a person was detected with sufficient confidence. When false,
  /// [landmarks] holds only absent entries — this flag is what distinguishes
  /// "no one was in frame" from "our detector had a bad frame" for a
  /// diagnostic, even though today both currently store the same landmark
  /// state (requirement 5.4).
  final bool personDetected;

  /// Resolved model identity string (e.g. a checksum-derived id), so a
  /// stored attempt is always attributable to a specific model
  /// (requirement 5.9). This package does not define the identity format;
  /// it only carries it through.
  final String modelVersion;

  /// A copy with [contentTimestamp] resolved. The only way this field is
  /// ever set — construction with it null, then exactly one resolution.
  PoseObservation withContentTimestamp(Duration contentTimestamp) =>
      PoseObservation(
        captureTimestamp: captureTimestamp,
        contentTimestamp: contentTimestamp,
        sequence: sequence,
        segmentId: segmentId,
        landmarks: landmarks,
        personDetected: personDetected,
        modelVersion: modelVersion,
      );
}
