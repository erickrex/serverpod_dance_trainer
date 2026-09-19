# Implementation Plan — Serverpod Dance Trainer

> Implementation update, 19 September 2026: the earlier "server never started" and "no gameplay code" notes below describe the initial scaffold and are superseded by `docs/verification.md`. The training flow, persisted attempts, practice loop, SMTP delivery and real native inference now have implementation and local checks. Checkboxes remain conservative because many numbered tasks also require device trials, reviewed beat annotations, deployment or learner evaluation. Those gates are not completed by a host test.


Deadline: **14 October 2026, 23:59 CEST**. No extensions. Judging access must hold until 20 October 17:00 CEST.

Phase dates are a proposed schedule. Move effort between phases as evidence requires, but protect Phase 6 (device and learner hardening) — it is what converts a demo into a submission that scores on "does it work" (30%, and the first tie-break).

Each task references the requirements it satisfies. Exit criteria are technical gates, not permission requests.

---

## Phase 0 — Standalone foundation (Sep 19–20)

**Exit criterion:** a fresh checkout verifies both source content sets, starts Flutter, and calls a real Serverpod endpoint.

- [x] 0.1 Initialize the repository independently and generate the Serverpod project scaffold with the selected released toolchain. Record exact Serverpod, Dart and Flutter versions in `README.md` and commit lockfiles.
  - Ensure the first commit is dated on or after 15 September 2026 17:30 CEST.
  - **Done 19 Sep.** Flutter 3.35.7 / Dart 3.9.2 installed and verified. `serverpod create dance_trainer` scaffolded `dance_trainer_server`, `dance_trainer_client` and `dance_trainer_flutter` (Serverpod 3.4.13 — 4.0.1 exists but was not targeted; **revisit before the version freeze in task 6.10**), then moved from the nested `dance_trainer/` folder the generator creates up to repo root to match design.md's layout. A root `pubspec.yaml` declares a Dart pub workspace over all four packages (`packages/dance_domain` + the three generated ones) so one `dart pub get` resolves everything together. Both generated packages pass `dart analyze` with zero issues. `dance_domain` is wired in as a real `path:` dependency on both the server and Flutter sides — proven by actually running code that calls it from inside `dance_trainer_server` (not just resolving in the analyzer), which printed the correct score. What's NOT done: no reachable, credentialed Postgres, so the server has never actually started (`serverpod_test` integration tests confirmed this by timing out after 30s waiting for a database — see `docs/toolchain_status.md`).
  - _Requirements: 1.1, 1.2, 18.2, 19.8_
- [x] 0.2 Create the `packages/dance_domain` pure Dart package with `pose/`, `scoring/`, `content/` and `test/fixtures/` directories and no Flutter, FFI or Serverpod dependency.
  - **Done 19 Sep.** `pose/` and `scoring/` are populated and tested; `content/` and `test/fixtures/` exist as empty directories pending task 2.x (content compiler, fixture traces).
  - _Requirements: 8.1_
- [x] 0.3 Add a CI import-boundary check that fails the build when `dance_domain` imports Flutter, FFI or Serverpod, or when the Flutter app imports the server package.
  - **Done 19 Sep, both halves.** `scripts/check_domain_boundary.sh` checks (a) `dance_domain`'s pubspec and imports for Flutter/FFI/Serverpod, and (b) `dance_trainer_flutter`'s pubspec and imports for a direct `dance_trainer_server` dependency. Both halves verified with a negative control — injecting the forbidden import/dependency makes the script fail with a specific message naming the offending line, removing it makes it pass again. Not yet wired into an actual CI runner — no CI provider is configured in this repo.
  - _Requirements: 8.1_
- [ ] 0.4 Set up formatting, static analysis, domain unit tests and server integration tests in CI.
  - _Requirements: 8.3_
- [ ] 0.5 Add environment configuration templates with no committed secrets, seed data, and a documented development account flow.
  - _Requirements: 18.4_
- [x] 0.6 Inventory the six source files, compute and commit SHA-256 checksums, and write `content/manifests/source_inventory.json` recording routine id, role, byte size, declared fps and frame count.
  - **Done 19 Sep.** All six files copied to `content/source/<routineId>/` and verified byte-identical. Origin tree is no longer referenced. `poses_backups/` (three timestamped archives) deliberately excluded.
  - _Requirements: 1.3, 1.5_
- [x] 0.7 Choose and implement the media distribution mechanism for ~178 MB of content (Git LFS or a checksum-verified artifact fetch script) and write `scripts/verify_content.sh`.
  - **Done 19 Sep.** Git LFS chosen over an external artifact store: the submission rules require the repository itself to contain every asset needed to run, and LFS satisfies that without putting 170 MiB into plain Git objects. Patterns are in `.gitattributes`; run `git lfs install` before the first commit. No `fetch_content.sh` is needed while content ships in-repo.
  - `verify_content.sh` fails loudly on a missing file or digest mismatch and passes against the copied content.
  - _Requirements: 1.3, 1.4, 3.3_
- [x] 0.8 Classify the preserved routines as **development content** and record that classification in `THIRD_PARTY_NOTICES.md` and the source manifest.
  - **Decided 19 Sep.** Permissions are deliberately not resolved for this content. It exists to prove the concept; original media replaces it before the demo video. Do not publish it, do not feature it in the submission video, and do not spend schedule on licensing it.
  - The swap itself is task 6.11; the pipeline requirement that makes the swap cheap is task 2.17.
  - _Requirements: 1.6, 1.7, 1.9_
- [x] 0.10 Audit the preserved content before building against it: real media durations and audio streams, pose timeline integrity, landmark confidence distribution and tracking identity stability.
  - **Done 19 Sep**, results in `docs/content_audit.md`. Outcomes: MP4 audio is the playback master for both routines; the reference timeline needs no repair; score on core landmarks rather than all 17; the routine build order is reversed.
  - _Requirements: 1.5_
- [ ] 0.9 Nominate the reference Android device and one lower-performance device, and record model, OS and build in `docs/device_validation.md`.
  - _Requirements: 17.6_

---

## Phase 1 — Pose and clock prototype (Sep 20–22)

**Exit criterion:** a physical phone distinguishes basic movements and yields trustworthy timestamps, with no mock inference anywhere in the path.

- [ ] 1.1 Select the trained pose model, verify its licence, and record `ModelIdentity`: source weights hash, expected input layout, dimensions, colour order, normalization, output format and supported delegates.
  - Do not infer the contract from the original project's `pose.pte` filename; it carries conflicting 192- and 256-pixel assumptions and includes a test-network exporter.
  - _Requirements: 5.9_
- [ ] 1.2 Export the model through the exporter matching the resolved ExecuTorch runtime and compare reference PyTorch output against ExecuTorch output on representative recorded frames.
  - Resolve the `executorch_flutter` (0.7.2 / runtime 1.4.0) versus upstream 1.5.0 question here and record the resolved runtime. Prefer XNNPACK CPU.
  - _Requirements: 5.1, 5.9_
- [ ] 1.3 Implement the `PoseEngine` interface and its ExecuTorch adapter, including model load, inference and disposal.
  - _Requirements: 5.1, 5.3_
- [ ] 1.4 Implement camera image-stream capture with preprocessing (sensor rotation correction, aspect-preserving letterbox, normalization) off the UI thread, preserving acquisition timestamps end to end.
  - _Requirements: 5.7, 5.8, 4.7_
- [ ] 1.5 Implement single-inference-in-flight backpressure with at most one newest pending frame and obsolete-frame dropping inside the adapter.
  - _Requirements: 5.6_
- [x] 1.6 Implement `LandmarkValidity` handling: low-confidence and absent landmarks carry an explicit validity value; no missing measurement is encoded as a zero coordinate.
  - **Done and tested 19 Sep**, ahead of the rest of Phase 1 (no device or ExecuTorch integration needed for the pure type). `packages/dance_domain/lib/src/pose/landmark.dart`: `Landmark`'s constructor asserts `x`/`y` are null if and only if `validity == absent`, closing off the exact origin-project bug (`{x:0, y:0, confidence:0}`) at the type level rather than by convention. What remains for Phase 1 proper: wiring this type to real ExecuTorch output on a device.
  - _Requirements: 5.5_
- [ ] 1.7 Implement person-absence detection that rejects low person confidence rather than selecting the highest-scoring candidate.
  - _Requirements: 5.4_
- [ ] 1.8 Implement `PlaybackClock` with capture-to-content-time anchoring, anchor refresh on player state change, and `segmentId` increments on pause, seek, loop and rate change.
  - _Requirements: 9.1, 9.2, 9.3, 9.4_
- [ ] 1.9 Build a throwaway diagnostic screen showing landmark overlay, measured inference rate, latency distribution and capture-to-content offset; record results on both devices.
  - _Requirements: 17.1, 17.3, 17.6_
- [ ] 1.10 Write tests for mirror transform, landmark indexing, aspect-ratio restoration and coordinate restoration after resize.
  - _Requirements: 4.5, 4.6_
- [ ] 1.11 If the community wrapper fails on the reference device, time-box a minimal native adapter investigation and record the outcome. Do not spend the remaining schedule on an unsupported model/runtime combination.
  - _Requirements: 5.1_

---

## Phase 2 — Content pipeline and scoring (Sep 23–26)

**Exit criterion:** source data is preserved and verified, and correct / late / wrong / stationary traces produce sensible, reproducible, distinguishable results.

- [ ] 2.1 Write the Dart import tool in `tools/content_pipeline/` that parses the existing JSON schema with no React Native or Python dependency, validating timestamps, fps, frame count, landmark names, coordinate ranges, confidence and source metadata.
  - Must handle both sampling rates independently: 60.0 fps / 12,012 frames and 30.0 fps / 5,131 frames.
  - _Requirements: 1.5_
- [ ] 2.2 Preserve original `angles` and model metadata for provenance while deriving the new feature set from the 17 landmarks. Do not treat the eight duplicated angle names as independent evidence, and do not carry the source's accuracy claim forward as app quality.
  - _Requirements: 8.10, 17.7_
- [x] 2.3 Implement `MediaProbe`: measure real MP3 and MP4 durations and audio tracks per routine, decide the audible playback master, and store verified offsets and trim mappings explicitly.
  - **Decided 19 Sep from measurement** (`docs/content_audit.md`): the **MP4's embedded AAC track is the playback master for both routines**, so the verified offset is zero by construction. The separate MP3s remain archival and are never played. `howdeepisyourlove.mp3` is 26.75 s longer than its video — the video is a trimmed excerpt from an unknown position, and using the MP3 would bake an unknown offset into every score for that routine.
  - Still to implement: the probe as a pipeline step that re-asserts this per routine, so distribution content cannot silently violate it.
  - _Requirements: 9.1_
- [ ] 2.4 Define the sidecar annotation format (beat markers with eight-count grouping and tempo changes, sections with stable ids and lead-ins, movement events with target time, type, required landmarks and tolerances, feedback definitions) and author annotations for **`howdeepisyourlove`** (routine 1).
  - Source JSON must remain unedited.
  - _Requirements: 11.3, 12.2_
- [ ] 2.4a Author exclusion intervals for routine 1 as sidecar annotations: the 42 tracking-instability clusters measured in `docs/content_audit.md`. Events overlapping an exclusion interval are unscoreable, not missed.
  - _Requirements: 8.7, 1.5_
- [ ] 2.5 Implement the deterministic `ContentCompiler` producing a versioned indexed runtime bundle, with every bundle linked to source hashes, annotation hashes and compiler version.
  - _Requirements: 3.3, 3.5_
- [ ] 2.6 Write compiler determinism and fidelity tests: identical inputs give byte-identical output, and compiled reference poses reconstruct representative source observations within documented tolerances.
  - _Requirements: 8.3_
- [ ] 2.7 Write the alignment test asserting that video, separate audio, reference poses and annotated beats agree at the start, middle and end of the full routine.
  - _Requirements: 9.1_
- [x] 2.8 Implement domain feature normalization: torso-centred shape features, robust body-scale normalization, unit limb directions and joint angles, with ankle-relative and trajectory features preserved rather than normalized away.
  - **Done and tested 19 Sep.** `lib/src/scoring/normalization.dart` (`estimateBodyScale`, `normalizeFeatures`, `NormalizedFeatures`). Body scale is shoulder-to-hip distance (stays measurable even when feet are cropped/occluded). Tested that scaled positions are invariant to the dancer's position and distance from camera, but a lateral step remains clearly distinguishable from feet-together (the exact property the spec calls out: "normalizing away would delete the exact thing a side step is scored on").
  - _Requirements: 8.1_
- [x] 2.9 Implement bounded event matching: search a window around each event's target content time, use the match for movement quality, retain the signed offset for timing quality, forbid one observation satisfying two events, and forbid unbounded warping.
  - **Done and tested 19 Sep.** `lib/src/scoring/event_matching.dart` (`ReferenceEvent`, `MatchableObservation`, `matchReferenceEvent`, `jointAngleSimilarity`, `timingSimilarity`). Tests confirm: a candidate exactly at the match-window edge is included, one microsecond past is excluded (bounded window, not unlimited warping); the CLOSEST-IN-TIME candidate is picked, not the best-scoring one (picking by score would let a lucky nearby frame stand in for what the dancer did at the actual beat); an unmeasurable angle is skipped rather than scored as a mismatch. "One observation cannot satisfy two events" is explicitly NOT enforced by this function — a test documents that as the caller's responsibility (removing a matched observation from the candidate pool before matching the next event), same as the aggregator's boundary from task 2.10.
  - _Requirements: 9.5, 9.6, 9.7_
- [x] 2.10 Implement the scorer: `eventQuality = 0.6 × movementQuality + 0.4 × timingQuality`, total on 0–10,000 over the full required event weight denominator, zero for observed-but-missed, unassessed for insufficient tracking, coverage reported alongside diagnostics.
  - **Done and tested 19 Sep.** `lib/src/scoring/attempt_score.dart` (`EventQuality`, `aggregateAttemptScore`). 44 tests pass, including an anti-gaming test proving an unassessed event can only ever lower the total, never raise it (requirement 8.5), and a formula test confirming the exact 0.6/0.4 weighting. What's NOT here yet: bounded event matching against a real reference bundle (task 2.9) — this task covers aggregation of already-matched results, which is the boundary the tests document explicitly.
  - _Requirements: 8.4, 8.5, 8.6, 8.7, 8.8_
- [x] 2.11 Implement the coverage gate and ranked-eligibility computation from `RunConditions`, suppressing the overall judgment below the gate and attributing the cause to observation rather than the student.
  - **Done and tested 19 Sep.** `lib/src/scoring/ranked_eligibility.dart` (`evaluateRankedEligibility`). Includes a test that walks every `EligibilitySuppressionReason` and asserts none of them read as blaming the student.
  - Define coverage over the landmarks each event actually requires, **not** over all 17. Measured: 94.4% / 93.3% of reference frames have all eight core landmarks above 0.5 confidence, but only ~59% have all seventeen — the gap is the face group, which no event needs. An all-17 gate would discard 41% of usable frames for nothing. **Encoded in `lib/src/pose/landmark.dart`'s `LandmarkFrame.hasCoreCoverage`, tested against the exact scenario (all-17 minus a face landmark still counts as full core coverage).**
  - _Requirements: 8.9, 6.5_
- [ ] 2.12 Implement deterministic error codes (`lateMovement`, `earlyMovement`, `armHeightMismatch`, `stepDirectionMismatch`, `insufficientTracking`), evidence-based priority, one-correction-at-a-time selection with cooldown, and template feedback wording.
  - _Requirements: 6.2, 6.3_
- [ ] 2.13 Record fixture traces on the reference device for correct, early, late, wrong-direction and stationary performance, and commit them as domain test fixtures.
  - _Requirements: 8.3, 17.5_
- [ ] 2.14 Write the negative-behaviour test suite: no reference-pose fallback, missing data never scores perfectly, unassessed events award nothing, and a hidden section cannot raise the total.
  - _Requirements: 5.2, 8.5, 8.7_
- [ ] 2.9a Implement the per-attempt matching loop that calls `matchReferenceEvent` once per reference event and removes a matched observation from the candidate pool before matching the next event, closing the gap tasks 2.9/2.10's tests deliberately left open (requirement 9.7 — "one observation cannot satisfy two events" is enforced HERE, not inside `matchReferenceEvent` or `aggregateAttemptScore`).
  - _Requirements: 9.7_
- [ ] 2.15 Implement per-section aggregation producing `AttemptSectionResult` values with evidence-backed error summaries.
  - _Requirements: 11.1_
- [ ] 2.16 Freeze the initial `ScoringConfiguration` version after tuning against the Phase 2.13 fixtures and document the constants in `docs/scoring.md`.
  - _Requirements: 8.10_
- [ ] 2.17 Prove the pipeline is routine-agnostic: add a routine through import → annotate → compile → register using only data files and a manifest entry, with no change to application, domain or server code.
  - This is what makes the later distribution-content swap (task 6.11) a data operation rather than a rewrite. Verify it now, while there is time to fix the abstraction, not in October.
  - **Extraction decided 19 Sep: reimplemented, not reused.** `tools/content_pipeline/pose_extract/extract_poses.py` replaces the origin project's `preprocess_video_yolov8.py`, fixing four defects (no track identity, swapped colour channels, angles computed in aspect-distorted space, missing data encoded as valid zeros). Output is schema v2; the preserved files stay v1. See that directory's README.
  - `audit_poses.py` alongside it reads both schemas and gates CI on timeline integrity, coverage and media alignment. Verified against both preserved routines.
  - **`extract_poses.py` is unrun** — no ultralytics, torch or GPU on the development host. Smoke-test it with `--limit 300` and A/B the colour-order fix before trusting any extraction.
  - _Requirements: 1.8_
- [ ] 2.18 Make the Dart importer read schema v1 and v2: v1 for the preserved routines (zeroed absent landmarks, eight angle keys collapsing to four, angles distorted by independent axis normalization) and v2 for anything newly extracted (explicit validity, null for unmeasurable, four correctly-named joint bends).
  - Derive features from landmarks in both cases. Never read a v1 angle as a measurement.
  - _Requirements: 1.5, 1.8_
- [ ] 2.19 Wire `audit_poses.py` into CI over every registered routine, with the coverage floor set from the frozen scoring configuration.
  - _Requirements: 1.4, 8.9_

---

## Phase 3 — Accounts and first full run (Sep 27–30)

**Exit criterion:** a real authenticated student completes a routine and retrieves the saved result after an app restart.

- [ ] 3.1 Define the Serverpod models and migrations for `UserProfile`, `Choreography`, `ChoreographyVersion`, `SectionDefinition`, `ScoringConfiguration`, `Attempt`, `AttemptChunk` and `AttemptSectionResult`, with the unique constraints from the design.
  - _Requirements: 7.4, 7.7, 2.4_
- [ ] 3.2 Configure the Serverpod authentication module with real email delivery for the deployed environment, and implement register, verify, sign in, refresh, recover and sign out.
  - _Requirements: 2.1, 2.5, 18.1_
- [ ] 3.3 Implement the profile endpoint (get/update own, set leaderboard visibility, request deletion) with server-derived ownership and no credential duplication.
  - _Requirements: 2.3, 2.4, 15.3_
- [ ] 3.4 Implement the catalog endpoint returning published routines and compatible immutable manifests with bundle locations, and register routine 1's manifest.
  - _Requirements: 3.1, 3.5_
- [ ] 3.5 Build the Flutter auth and onboarding flow: welcome, create account, verification, display name and experience level, preset avatar.
  - _Requirements: 2.1, 2.2, 2.3_
- [ ] 3.6 Build the catalog and detail screens with download status, and implement local bundle caching with checksum verification gating the start action.
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.6_
- [ ] 3.7 Build the camera setup screen: pre-permission explanation of on-device processing, silhouette guide, per-group landmark checks, a stable 2-second observation window gate, and one persisted mirror transform per session.
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
- [ ] 3.8 Implement the gameplay state machine `selecting → downloading → settingUp → countingIn → running → finishing → results` with side states `pausedPractice`, `trackingLost`, `recoverableError`, `aborted`, explicit resource ownership per transition, single disposal, and generation tokens.
  - _Requirements: 16.1, 16.3, 16.4_
- [ ] 3.9 Gate the count-in on model loaded, bundle parsed, camera streaming and player ready, and implement the eight-count lead-in.
  - _Requirements: 4.8_
- [ ] 3.10 Build the run screen: prominent instructor, smaller camera preview, optional skeleton overlay, large score and combo, infrequent legible feedback.
  - _Requirements: 6.1, 6.2_
- [ ] 3.11 Implement interruption handling: camera loss suspends judgment, processing delay drops stale frames and resumes at the correct content time, pause/seek/backgrounding ends ranked eligibility, model failure stops scoring without a score.
  - _Requirements: 5.3, 6.5, 6.6, 6.7_
- [ ] 3.12 Implement the ranked attempt ticket: server-issued opaque ticket bound to content and scoring version with an expiry covering routine duration plus upload grace, sized for the ~200-second routine.
  - _Requirements: 7.1_
- [ ] 3.13 Implement the durable SQLite outbox with per-account partitioning, appending compact observations during the run at an initial 10–15 observations per second.
  - _Requirements: 7.2, 7.8_
- [ ] 3.14 Implement sequenced idempotent chunk upload with explicit payload limits (initial targets: chunk under 256 KiB, attempt budget around 6 MiB) that fails with an actionable error rather than truncating.
  - _Requirements: 7.3, 7.4, 7.12_
- [ ] 3.15 Implement server finalization: completeness, ticket, version and coverage checks, authoritative recomputation with `dance_domain`, and a single transaction writing attempt result, section results, progress and leaderboard update.
  - _Requirements: 8.2, 8.3, 7.5, 7.6_
- [ ] 3.16 Implement outbox retry with bounded exponential backoff, resume from last acknowledged chunk, app-restart recovery, and auth-expiry handling that never re-attributes queued evidence.
  - _Requirements: 7.8, 7.9_
- [ ] 3.17 Implement ticket-expiry handling: save as unranked history, exclude from leaderboards, state the reason.
  - _Requirements: 7.10_
- [ ] 3.18 Build the results screen: total, movement and timing subscores, combo, coverage, personal-best comparison, final/pending/unranked marking with reason, section timeline, plain-language recommendation, and the "Practice this section" primary action.
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_
- [ ] 3.19 Implement the insufficient-evidence result path recommending camera adjustment and retry without inventing a dance correction.
  - _Requirements: 10.6_
- [ ] 3.20 Write server integration tests for cross-account rejection, idempotent upload and finalization, chunk sequence conflict, and duplicate finalization returning the existing result.
  - _Requirements: 7.4, 7.6, 15.4_
- [ ] 3.21 Write the client/server scoring parity test running identical fixtures through both tiers with the same configuration version.
  - _Requirements: 8.3_

---

## Phase 4 — Practice loop (Oct 1–4)

**Exit criterion:** result → practice section → measured drill → replay works end to end.

- [ ] 4.1 Add the `PracticeAssignment` and `DrillRepetition` models and migrations with unique `(assignment, repetitionIndex)`.
  - _Requirements: 12.8_
- [ ] 4.2 Implement deterministic server-side section ranking by supported error severity and recurrence, gated on per-section coverage, selecting an annotated musical section.
  - _Requirements: 11.1, 11.2, 11.3, 11.6_
- [ ] 4.3 Implement typed fallback recommendations (`recalibrateCamera`, `replayRoutine`, `optionalRefinement`) for the no-reliable-error case.
  - _Requirements: 11.5, 10.7_
- [ ] 4.4 Implement the practice endpoint: get recommendation for an owned attempt, start assignment, record and finalize repetitions, complete assignment.
  - _Requirements: 11.4, 13.4_
- [ ] 4.5 Build the drill screen: assignment load, short preview, musical count-in, three measured normal-speed repetitions, per-repetition timestamp origin and observation flush between repetitions.
  - _Requirements: 12.1, 12.2, 12.3, 12.5_
- [ ] 4.6 Implement drill completion based on sufficient tracking coverage across the required repetitions, without implying mastery, and offer another attempt when performance remains weak.
  - _Requirements: 12.6, 12.7_
- [ ] 4.7 Build the drill result screen comparing the focus metric before and after only across comparable speed, model, content and scoring versions, stating the concrete observed change.
  - _Requirements: 13.1, 13.2_
- [ ] 4.8 Implement the replay action as the primary next step and ensure assignment completion updates progress exactly once.
  - _Requirements: 13.3, 13.4_
- [ ] 4.9 Implement the offline provisional recommendation using the same selection rules, labelled pending sync and replaced by the server result after upload.
  - _Requirements: 11.7_
- [ ] 4.10 Write tests for timestamp mapping across loop resets and for one repetition's observations not affecting the next.
  - _Requirements: 9.4, 12.5_
- [ ] 4.11 Verify normal-speed looping is stable before attempting slow playback; only then evaluate 0.75× synchronization and gate the feature on the measurement.
  - _Requirements: 12.4_

---

## Phase 5 — Leaderboard and second routine (Oct 5–7)

**Exit criterion:** both original routines are playable, two users produce valid rankings, and practice and invalid runs are excluded.

- [ ] 5.1 Add `UserChoreographyProgress` and `LeaderboardEntry` models with unique `(boardKey, user)` and indexes for `(user, createdAt)` and `(boardKey, score DESC, achievedAt, id)`.
  - _Requirements: 14.4, 14.6_
- [ ] 5.2 Implement board partitioning by content version, difficulty, scoring version and compatible model cohort.
  - _Requirements: 14.1, 14.2_
- [ ] 5.3 Implement ranked-eligibility enforcement excluding paused, slowed, sought, offline-started, interrupted, incomplete and drill attempts.
  - _Requirements: 14.3, 13.7, 16.6_
- [ ] 5.4 Implement atomic concurrency-safe personal-best updates and write a concurrent-finalization test.
  - _Requirements: 14.5_
- [ ] 5.5 Implement leaderboard and progress endpoints with deterministic pagination, current-user rank, visibility filtering, and no private field exposure.
  - _Requirements: 14.6, 2.7, 2.8_
- [ ] 5.6 Build the leaderboard and progress screens, including the honest empty state and version-filtered trends with no blended improvement percentage.
  - _Requirements: 14.7, 13.5, 13.6_
- [ ] 5.7 Author annotations and exclusion intervals for **`30minutos`** (routine 2) and compile it through the same pipeline, validating full-length audio, video and pose alignment at its 60 fps sampling rate.
  - Budget more time than routine 1 took: 12,012 frames against 5,131, 13.6% of frames inside tracking-unstable spans against 1.9%, and 490 person-absent frames (8.2 s) needing explicit exclusion. See `docs/content_audit.md`.
  - _Requirements: 3.7, 1.5_
- [ ] 5.8 Register routine 2's manifest and test it end to end, including bundled-versus-downloaded acquisition.
  - _Requirements: 3.7, 3.8_
- [ ] 5.9 Build the settings screen: mirror preference, skeleton overlay, audio cues, download management, profile editing, leaderboard visibility, sign-out and account deletion.
  - _Requirements: 15.1_
- [ ] 5.10 Implement the documented account-deletion server workflow removing results, drills, progress and leaderboard records.
  - _Requirements: 15.2_
- [ ] 5.11 Implement the documented pose-trace retention policy, structured logging with no token or payload contents, and request-rate limits with plausibility checks.
  - _Requirements: 15.6, 15.7, 18.5, 14.8_

---

## Phase 6 — Device and learner hardening (Oct 8–11)

**Exit criterion:** acceptance scenarios pass on real devices and learners can explain the feedback they received.

- [ ] 6.1 Run consented learner trials with several people of differing height, clothing and routine familiarity, varying distance and lighting within the advertised envelope; record sessions and outcomes in `docs/device_validation.md`.
  - _Requirements: 17.6_
- [ ] 6.2 Measure and record sustained pose rate, p95 capture-to-feedback latency, memory and thermal behaviour in release builds on both nominated devices.
  - _Requirements: 17.1, 17.3, 17.6_
- [ ] 6.3 Run the ten-minute repeated-attempt stability test checking for crashes, unbounded memory growth and a growing frame queue.
  - _Requirements: 17.4_
- [ ] 6.4 Verify a known injected timing offset is recovered from a recorded trace within the documented tolerance, and record the smoothing-induced delay.
  - _Requirements: 17.5, 9.9_
- [ ] 6.5 Confirm with learners that false corrections are rare enough to be trusted and that they can restate the selected correction in their own words; have a competent bachata dancer review the event vocabulary and wording.
  - _Requirements: 6.3, 10.4_
- [ ] 6.6 Implement visible degradation when the sustained rate makes event timing unreliable: widen tolerances or mark the run unranked.
  - _Requirements: 17.2_
- [ ] 6.7 Run the full-flow acceptance scenario from a clean install through replay and leaderboard, then restart and confirm history persists; repeat with a second account for privacy and ranking.
  - _Requirements: 16.5, 2.6, 2.8_
- [ ] 6.8 Run the acceptance scenario twice more — once with network loss after gameplay begins, once with deliberately poor tracking — and confirm both end in understandable states with no fabricated score.
  - _Requirements: 7.9, 8.9, 10.6_
- [ ] 6.9 Fix failures observed on devices and with learners before adding any further feature.
- [ ] 6.10 Freeze content, scoring and model versions so final results are comparable, and record the frozen identifiers.
  - _Requirements: 8.10, 18.6_
- [ ] 6.11 Swap in distribution content: record or license media the entrant may publish, extract pose data in the same schema, annotate, compile, register, and validate one routine end to end on it.
  - Gate for the demo video — task 7.6 cannot use development content.
  - Depends on task 2.17 having proved the pipeline routine-agnostic, and on the pose-extraction path existing. New footage has no pose JSON.
  - Minimum viable version: one routine, one dancer, music the entrant owns or that is licensed for publication. It does not need to be as long or as polished as the development routines; it needs to be publishable and to score.
  - If this slips, the submission ships with development content in the repository and a demo video built around the publishable routine only, per requirement 1.9.
  - _Requirements: 1.7, 1.8, 1.9, 19.4_

---

## Phase 7 — Submission build (Oct 12–14)

**Exit criterion:** a fresh-install test passes against the deployed backend and every required material is ready before 23:59 CEST on 14 October.

- [ ] 7.1 Deploy the backend and validate authentication, email delivery, migrations, asset serving and HTTPS configuration in the production environment.
  - _Requirements: 18.1_
- [ ] 7.2 Complete the `README.md` with exact versions, local startup and migration steps, client generation, physical-device-to-local-backend instructions, asset fetch from a clean checkout, Android build and install steps, device requirements, known limitations, test commands and production deployment, health check, migration and rollback procedures.
  - _Requirements: 18.2, 18.3_
- [ ] 7.3 Audit the repository for credentials in source, example configuration, lockfiles and logs.
  - _Requirements: 18.4_
- [ ] 7.4 Produce the release APK, record it together with its matching source revision, and run the clean-checkout-to-clean-install test.
  - _Requirements: 18.7, 1.1_
- [ ] 7.5 Create the judging account and place its credentials in the private testing instructions, not in public source.
  - _Requirements: 19.7_
- [ ] 7.6 Record the under-two-minute demonstration video following the 110-second structure, using real tracking, real server writes and real leaderboard state.
  - Structure: 0–15s problem, account, selection · 15–45s live tracking and scoring · 45–65s saved result and evidence-backed correction · 65–90s "Practice this section" and a measured repetition · 90–110s completed drill, saved progress, real leaderboard.
  - Use only permitted music and visual assets; no third-party marks; no Just Dance branding.
  - _Requirements: 19.4, 19.5, 1.7_
- [ ] 7.7 Upload the video publicly to YouTube or Vimeo and verify it plays without sign-in.
  - _Requirements: 19.4_
- [ ] 7.8 Write the submission text description covering features, how it was built, build and run instructions, and disclosure of AI coding tools and model components.
  - _Requirements: 19.6_
- [ ] 7.9 Share the repository with the three Serverpod judging addresses if it is private, and confirm access.
  - _Requirements: 19.3_
- [ ] 7.10 Submit before 14 October 23:59 CEST and confirm the backend and build remain reachable free of charge through 20 October 17:00 CEST.
  - _Requirements: 19.1, 19.2_
- [ ] 7.11 Submit one feedback submission with actionable comments on the Serverpod SDKs, App Studio or documentation.
  - _Requirements: 19.9_
- [ ] 7.12 Publish at least one public build-in-progress or finished-project post identifying the hackathon.
  - Optional, targets the Best Hackathon Post prize; keep it to spare time only.

---

## Scope reduction order if work slips

Cut in this order. Do not reorder without recording why.

1. Cosmetic animation and UI polish.
2. Slow (0.75×) practice playback.
3. Extended trend charts.
4. Optional avatar customization.
5. Number of distinct correction types.
6. Number of annotated practice sections.

**Never cut, and never silently degrade:** routine 1 (`howdeepisyourlove`) at full length, authentication, real on-device tracking, server-saved results, one complete targeted drill, or leaderboard eligibility rules.

Routine 2 (`30minutos`) is the contingency. It carries seven times the tracking instability and more than twice the annotation work, so if Phase 5 is tight it slips rather than compressing the practice loop or the device hardening. Say so in the submission text instead of shipping it half-annotated.

Task 6.11 (distribution content) is not on this list and is not optional in the same way: without it the demo video has nothing publishable to show. If everything else is at risk, a short publishable routine beats a second unpublishable one.
