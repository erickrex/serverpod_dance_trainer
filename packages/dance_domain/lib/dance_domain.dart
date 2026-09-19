/// Pure Dart scoring, pose and content domain for Serverpod Dance Trainer.
///
/// Zero dependency on Flutter, FFI or Serverpod (design.md "Dependency
/// boundaries") — this is what lets `dance_trainer_flutter` (provisional,
/// on-device) and `dance_trainer_server` (authoritative) run the exact same
/// scoring code and get identical results on identical input (requirement
/// 8.3). Importing anything from those layers here is a design bug, not a
/// style preference; task 0.3 enforces the absence in CI.
library;

export 'src/pose/geometry.dart';
export 'src/pose/landmark.dart';
export 'src/pose/pose_observation.dart';
export 'src/scoring/attempt_score.dart';
export 'src/scoring/event_matching.dart';
export 'src/scoring/normalization.dart';
export 'src/scoring/ranked_eligibility.dart';
export 'src/content/training.dart';
