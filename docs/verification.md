# Verification, 19 September 2026

The project has a working implementation and several verified paths. It is not yet a fully validated release. This record supersedes the earlier scaffold-only status.

## Changes made after the review

- Replaced the greeting screen with routines, setup, instructor playback, camera tracking, results, history, profile settings and section practice.
- Added a CameraX bridge with capture timestamps, bounded frame processing, actual YUV-to-RGB conversion, and the trained ExecuTorch pose model. Loss of observations stops assessment. There is no reference-pose fallback.
- Added authenticated Serverpod endpoints and migrations for attempts, evidence chunks, profiles, best results and practice completion. Ownership comes from the session. Retried chunks and finalization are idempotent. The server recomputes results using the shared scorer.
- Added a SQLite evidence queue, checksum-verified asset downloads, manual/startup upload retry and account separation. A low-coverage practice run saves without falsely counting a repetition.
- Fixed the arms-up/arms-down false match, timing points for wholly mismatched movement, reused observations, partially null landmarks, invalid quality/weight values and nonfinite geometry. Missing data reduces coverage and suppresses displayed judgments.
- Added development bundle compilation with image aspect restoration, source-rate handling and tracking exclusions. Source content is unchanged. Extraction refuses archival paths, existing output, symlinks into the archive and traversal.
- Replaced verification-code logging with SMTP delivery. Reworked the server Dockerfile to include the shared domain and runtime content. Added ignored local secret generation and removed literal database credentials from Compose.

## Verified locally

| Check | Result |
|---|---|
| Static analysis and formatting | No analyzer issues; formatting check passes |
| Domain tests | 79 passing |
| PostgreSQL integration tests | 11 passing, including ownership, retries, score parity, profiles and practice completion |
| Flutter tests | 5 passing, including trained-model inference and low-coverage result suppression |
| Extractor safety tests | 4 passing |
| Source checksums | All six original files match the inventory |
| Content compilation | Both bundles and sidecars regenerate byte-identically |
| Dependency boundary check | Pass |
| Native pose inference, Linux x64 | Recorded dancer detected; mirrored coordinates/indices checked; empty image produces absent landmarks |
| Live Serverpod assets | Model HTTP 200, correct 13,363,716-byte size; MP4 range request HTTP 206, 1,024-byte response |
| SMTP transport | Registration and reset messages delivered to a local SMTP capture process; bodies checked without printing codes |
| Android build | Debug arm64 APK built, including the CameraX bridge and ExecuTorch native library |
| Server compilation | Isolated server/domain workspace resolves and compiles an executable with Dart 3.10.8 |

The endpoint tests use the real PostgreSQL server and transactional rollback. Recorded poses appear only in test fixtures and content compilation, never as learner observations. The local SMTP capture is a temporary test process, not app wiring. No fake or stub class is reachable from shipped Dart code.

## Remaining validation and scope

- No physical Android device was connected. Camera orientation, capture-clock compatibility, preview behavior, full-body setup, audio synchronization, interruptions, offline recovery, thermals and sustained inference throughput require a device trial. Host inference performance is not a phone measurement.
- The two routines contain automatically derived development pose checkpoints. They do not have reviewed beat grids, transition annotations or validated pedagogical feedback. `reviewed` is false, and ranked results remain disabled for them. The current countdown is a three-second start cue, not a musical eight-count.
- The current scorer evaluates visible 2D checkpoint poses. It does not establish learner improvement, partner connection, foot pressure, 3D motion or mastery. The broader specification's trajectory matching, calibrated timing and learner trials remain work.
- History currently loads the latest 30 saved attempts. Account deletion, download management, resumable interrupted runs and the broader progress comparisons are not implemented. Completed runs can be retried after network failure; interrupted runs must restart.
- Content versions must remain available to finalize queued evidence. The current content store serves the installed development version and refuses an unavailable version rather than rescoring with a replacement.
- Production SMTP, HTTPS hosting, database operations, release signing and distribution are not configured or deployed. A Docker daemon was unavailable, so the image itself has not been built; its Dart build stage was reproduced in an isolated workspace.
- A GitHub Actions workflow was added but has not run on a hosted runner. This working directory has no Git repository metadata, so no commit or pull request was created.
- Publication permissions for the archived choreography are unresolved. The added YOLO pose model has upstream AGPL-3.0 attribution. Original release content and the project's distribution license still need decisions.

## Documentation checked

Serverpod's [static file documentation](https://docs.serverpod.dev/concepts/web-server/static-files) was checked alongside the pinned 3.4.13 implementation, and verified by HTTP requests. Database ownership and atomic updates follow [Serverpod transactions](https://docs.serverpod.dev/3.4.0/concepts/database/transactions). Authentication and test helper signatures were checked against the installed 3.4.13 packages. The model is pinned to the [upstream 1.3.1 artifact index](https://raw.githubusercontent.com/abdelaziz-mahdy/executorch_flutter_models/main/1.3.1/index.json), with its actual tensor contract checked by executing inference.
