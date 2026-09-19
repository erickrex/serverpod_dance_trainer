# Requirements — Serverpod Dance Trainer

## Introduction

Serverpod Dance Trainer is a Flutter and Dart dance game that teaches a student bachata choreography through scored attempts and targeted practice drills. Serverpod is the backend: it owns authentication, profiles, choreography metadata, attempt finalization, practice selection, progress and leaderboards.

The defining loop is: choose a choreography → dance with camera tracking → receive a score and one specific correction → tap "Practice this section" → complete the drill → replay and improve.

This is a new implementation inspired by the existing Bacha Trainer React Native project. The architecture changes completely; the content does not. The two existing routines — their audio, video and movement JSON — are preserved byte-for-byte as source content. The new project must build and run from its own repository with no dependency on the original application, its dependencies or its development environment.

Numeric thresholds in this document are initial engineering targets to validate on real devices, not measurements. Where a target is unvalidated it is marked as such and the corresponding task requires it to be measured and recorded before being frozen.

**Source of truth for scope:** `new_ServerPod_Dance_Trainer.MD` (copied into this repository as `docs/project_plan.md`).
**Source of truth for competition constraints:** `docs/rules_serverpod_hackathon.md`.

### Verified content inventory

Confirmed present in the originating workspace on 19 September 2026:

| Routine ID | Audio | Video | Movement JSON | Sampling |
|---|---|---|---|---|
| `30minutos` | 4.81 MB MP3 | 82.65 MB MP4 | 34.91 MB JSON | 60.0 fps, 12,012 frames |
| `howdeepisyourlove` | 4.75 MB MP3 | 36.11 MB MP4 | 15.08 MB JSON | 30.0 fps, 5,131 frames |

Both JSON files declare `modelVersion: yolov8s-pose` and contain per-frame `keypoints` (17 named COCO landmarks with `x`, `y`, `confidence`) and `angles`. Total media footprint is approximately 178 MB, which requires a deliberate distribution mechanism rather than plain Git objects.

---

## Requirement 1 — Standalone repository and content preservation

**User story:** As a judge or a new contributor, I want to clone one repository and build the whole system, so that I never need the original React Native project or an undocumented local directory.

### Acceptance criteria

1. WHEN the repository is cloned to an empty directory THEN the documented setup steps SHALL produce a running Serverpod backend and a buildable Flutter Android application without referencing any path outside the new repository or its documented artifact source.
2. THE repository SHALL contain no import, build script, asset path or configuration value that resolves into the original Bacha Trainer project tree.
3. WHEN the content acquisition step runs on a fresh checkout THEN all six source files (two MP3, two MP4, two JSON) SHALL be obtained and verified against recorded SHA-256 checksums.
4. IF a content checksum does not match THEN the acquisition step SHALL fail with the offending file and expected digest, and SHALL NOT produce a playable routine.
5. THE original MP3, MP4 and JSON bytes SHALL be treated as immutable archival source; derived bundles and annotations SHALL be stored separately and SHALL NOT overwrite source files.
6. THE preserved routines SHALL be treated as **development content**: usable for building, testing and private device validation, never published, and never featured in the public demonstration video.
7. THE project SHALL swap in **distribution content** — media the entrant owns or is licensed to publish — before the submission video is recorded, and `THIRD_PARTY_NOTICES.md` SHALL record the permission basis for every file that ships.
8. THE content pipeline SHALL be routine-agnostic, so that adding distribution content is a data operation (import, annotate, compile, register) requiring no change to application or scoring code.
9. WHERE distribution content is not ready by the submission deadline THE submission SHALL feature only content the entrant may lawfully publish, and the text description SHALL state plainly which routines exist as development content.

### Build order

`howdeepisyourlove` is routine 1 and `30minutos` is routine 2, reversing the originating plan. This is measured, not arbitrary: see `docs/content_audit.md`. `howdeepisyourlove` has 1.9% of frames inside tracking-unstable spans against 13.6%, zero person-absent frames against 490, and 5,131 frames to annotate against 12,012.

---

## Requirement 2 — Account and profile

**User story:** As a student, I want an account, so that my results, drills and progress persist across devices and reinstalls.

### Acceptance criteria

1. WHEN a visitor submits a valid email and password THEN the system SHALL create an account through the Serverpod authentication module and send a verification message.
2. WHILE an account is unverified THE system SHALL NOT permit a ranked attempt, and SHALL state what is required.
3. WHEN an authenticated user first signs in THEN the system SHALL request a display name and experience level and SHALL create exactly one `UserProfile` linked to the framework auth record.
4. THE `UserProfile` SHALL NOT store password material or any credential; credentials SHALL remain in the framework's authentication tables.
5. WHEN a user requests account recovery THEN the system SHALL complete a password reset through the framework flow.
6. WHEN a user signs out THEN the client SHALL clear cached tokens and SHALL NOT expose the previous user's queued attempts or local results to a subsequent account.
7. WHERE leaderboard visibility is off THE system SHALL omit that user from all leaderboard responses while continuing to record their personal progress.
8. THE system SHALL never include an email address or private profile field in any leaderboard or public response.

---

## Requirement 3 — Choreography catalog and content acquisition

**User story:** As a student, I want to browse available routines and have the needed files ready before I dance, so that a run never fails partway through for a missing asset.

### Acceptance criteria

1. WHEN the catalog loads THEN the system SHALL list every published choreography with title, difficulty, duration, thumbnail, personal best and local download status.
2. WHEN a user opens a choreography detail screen THEN the system SHALL show a preview, the movements practiced and a start action.
3. THE start action SHALL be disabled until the complete content bundle for the selected immutable content version is present locally and checksum-verified.
4. WHEN a content download fails THEN the system SHALL present a retry action and the failure reason, and SHALL resume rather than restart where the transport supports it.
5. IF the local application cannot satisfy a bundle's declared compatible scoring or model version THEN the system SHALL refuse to start and SHALL state that an app update is required.
6. THE system SHALL NOT begin a ranked run that depends on media streaming arriving on time.
7. THE catalog SHALL contain both preserved routines, `30minutos` and `howdeepisyourlove`, as the default content.
8. WHERE only one routine is bundled in the installed application THE second SHALL download on selection with visible progress.

---

## Requirement 4 — Camera setup and calibration

**User story:** As a student, I want the app to confirm my camera can see me before scoring starts, so that I am not judged on frames that never captured my body.

### Acceptance criteria

1. WHEN the user reaches setup THEN the system SHALL explain that frames are processed on the phone and that camera video is not uploaded, before requesting the camera permission.
2. IF the camera permission is denied THEN the system SHALL explain the consequence and offer a route to system settings, and SHALL NOT enter gameplay.
3. WHILE in setup THE system SHALL show a silhouette guide and per-group visibility checks for shoulders, hips, knees and ankles.
4. THE start action SHALL remain disabled until all required landmark groups are detected above the configured confidence gate continuously for a stable observation window of at least 2 seconds.
5. WHEN setup completes THEN the system SHALL persist exactly one explicit mirror transform for the session, and SHALL apply it consistently to preview rendering, model output and reference comparison.
6. THE system SHALL NOT infer left/right independently per frame.
7. THE system SHALL fix the intended screen orientation for the release and SHALL correct for camera sensor rotation so that landmark coordinates are restored to the displayed geometry.
8. THE count-in SHALL begin only after the model is loaded, the reference bundle is parsed, the camera is streaming and the media player reports ready.

---

## Requirement 5 — On-device pose inference

**User story:** As a student, I want my real movement measured, so that the score reflects what I did.

### Acceptance criteria

1. THE system SHALL run a trained pose model on the device through ExecuTorch and SHALL produce all 17 COCO landmarks with `x`, `y` and `confidence` per observation.
2. THE production build SHALL contain no mock keypoint generator, no synthetic pose path and no fallback that substitutes reference poses for student poses.
3. IF inference fails or the model cannot be loaded THEN the system SHALL stop scoring, surface a recovery action, and SHALL NOT emit a score.
4. WHEN no person is detected with sufficient confidence THEN the observation SHALL be marked person-absent rather than resolved to the highest-scoring candidate.
5. THE system SHALL represent a missing or low-confidence landmark with an explicit validity value and SHALL NOT encode a missing measurement as a zero coordinate or zero angle.
6. THE system SHALL permit at most one inference in flight with at most one newest pending frame, and SHALL drop obsolete frames rather than accumulate a queue.
7. THE system SHALL preserve each frame's acquisition timestamp through preprocessing and inference, and SHALL NOT derive a dance timestamp from processed-frame count or inference completion time.
8. THE system SHALL perform image conversion and inference off the UI thread.
9. THE resolved model identity — source weights, checksum, input layout and dimensions, colour order, normalization, output format, delegate and export toolchain version — SHALL be recorded in the repository and SHALL NOT be inferred from a filename.

---

## Requirement 6 — Real-time gameplay feedback

**User story:** As a student dancing several metres from my phone, I want feedback I can read and act on while moving, so that I can correct myself mid-routine.

### Acceptance criteria

1. WHILE a run is active THE system SHALL show the instructor prominently, a smaller camera preview, and score and combo at a size legible from dancing distance.
2. THE system SHALL issue at most one actionable correction at a time and SHALL apply a cooldown so that advice does not flicker between codes.
3. THE system SHALL issue a movement correction only where the routine's annotated event and the observed landmarks both support it.
4. WHEN local scoring updates THEN the displayed provisional score SHALL update immediately, and the system SHALL indicate that the saved result is pending until the server finalizes it.
5. WHERE tracking is lost THE system SHALL suspend judgment, prompt repositioning, and SHALL NOT accrue missed-event penalties for the unobserved interval beyond marking it unassessed.
6. WHEN a pause, seek or app backgrounding occurs THEN the system SHALL end ranked eligibility for that attempt and SHALL offer restart or continuation as unranked practice.
7. WHEN a processing delay occurs THEN the system SHALL discard stale frames and resume from the correct media timestamp rather than replaying the backlog.

---

## Requirement 7 — Attempt evidence capture and reliable upload

**User story:** As a student on an unreliable connection, I want a completed dance to survive a dropout or an app restart, so that my work is never silently lost or double-counted.

### Acceptance criteria

1. WHEN a ranked run starts THEN the client SHALL obtain a server-issued opaque run ticket bound to a specific content version and scoring version, with an expiry covering the routine duration plus a documented upload grace period.
2. THE client SHALL append compact observations to durable local storage as the run proceeds, so that a process termination does not lose a completed run.
3. THE client SHALL upload evidence as sequence-numbered chunks and SHALL make retries idempotent.
4. THE server SHALL reject a chunk that reuses an existing sequence number with different bytes as an explicit conflict, and SHALL accept a byte-identical retry as a no-op.
5. WHEN the client requests finalization THEN it SHALL declare the expected chunk count and final content timestamp, and the server SHALL verify completeness before scoring.
6. THE server SHALL commit finalization exactly once, and a repeated finalization request SHALL return the existing final result.
7. THE pair `(user, clientAttemptUuid)` SHALL be unique so that a retried start cannot create a duplicate attempt.
8. IF authentication expires while items are queued THEN the client SHALL require sign-in before syncing and SHALL NOT attach one account's queued evidence to another account.
9. WHEN the app restarts with pending completed attempts THEN the client SHALL recover and resume the outbox from the last acknowledged chunk using bounded exponential backoff.
10. IF a ranked ticket expires before valid upload THEN the attempt SHALL be savable as unranked history and SHALL NOT enter a leaderboard.
11. THE evidence payload SHALL contain normalized landmarks, confidence, timestamps and run-state changes only; camera pixels SHALL NOT leave the device.
12. THE system SHALL enforce explicit serialized payload limits and, if exceeded, SHALL fail with an actionable error rather than silently truncating evidence.

---

## Requirement 8 — Server-authoritative scoring

**User story:** As a student comparing myself to others, I want the saved score computed by the same rules for everyone, so that the leaderboard means something.

### Acceptance criteria

1. THE scoring logic SHALL live in one pure Dart domain package with no Flutter, FFI or Serverpod dependency, and SHALL be executed by both the client (provisional) and the server (authoritative).
2. WHEN the server finalizes an attempt THEN it SHALL recompute the score from submitted observations using the referenced immutable scoring configuration, and SHALL NOT accept a client-supplied total.
3. GIVEN the same recorded trace and the same content, scoring and model versions, THE client and server SHALL produce an identical result.
4. THE total SHALL be on a 0–10,000 scale computed as `round(10000 * Σ(eventWeight × eventQuality) / Σ(allReferenceEventWeights))`, where `eventQuality = 0.6 × movementQuality + 0.4 × timingQuality` for an assessable event.
5. THE denominator SHALL include the routine's full required event set, so that unobserved or skipped sections cannot raise a score.
6. WHEN a movement is clearly observed but not performed THEN that event's quality SHALL be zero.
7. WHEN tracking is insufficient for an event THEN that event SHALL be marked unassessed, SHALL award no points, and SHALL NOT be treated as a successful match.
8. THE system SHALL report weighted event coverage alongside every movement and timing diagnostic average.
9. IF weighted event coverage falls below the configured gate (initial target 85%) or a long required section is unobserved THEN the system SHALL suppress the overall performance judgment and mark the run unranked, and SHALL attribute the cause to observation rather than to the student.
10. THE movement and timing weights, similarity functions, timing tolerances and coverage gates SHALL be tuned against recorded device trials and then frozen under an immutable scoring version identifier.
11. THE combo indicator SHALL NOT contribute a multiplier to the leaderboard score in this release.

---

## Requirement 9 — Time alignment

**User story:** As a student who danced the right move slightly late, I want that distinguished from dancing it wrong, so that the feedback tells me which problem I actually have.

### Acceptance criteria

1. THE system SHALL map monotonic camera capture time to media content time through an anchored playback clock, and SHALL refresh the anchor on player state changes.
2. THE system SHALL store beat markers and event targets in content time.
3. WHEN playback rate is not 1.0 THEN the system SHALL map wall-clock time through the actual rate.
4. WHEN a pause, seek, loop boundary or playback discontinuity occurs THEN the system SHALL start a new time segment and flush pending observations.
5. THE system SHALL match each reference event within a bounded window around its expected time, SHALL use the matched observation for movement quality, and SHALL retain its signed offset for timing quality.
6. THE system SHALL NOT apply unbounded time warping that would erase a late or early execution.
7. ONE student observation SHALL NOT satisfy more than one reference event.
8. THE system SHALL report "early" or "late" only where confidence and observation density support the judgment; on devices producing sparse observations it SHALL widen tolerances or mark the run unranked rather than assert fabricated precision.
9. WHERE smoothing is applied THE induced delay SHALL be measured and included in timing validation.

---

## Requirement 10 — Results

**User story:** As a student who just finished dancing, I want to see how I did and what to fix, so that I know what to do next.

### Acceptance criteria

1. WHEN a run completes THEN the system SHALL present total score, movement subscore, timing subscore, combo, tracking coverage and personal-best comparison.
2. THE result SHALL be clearly marked as final, awaiting upload, or unranked, with the reason for any non-final state.
3. THE system SHALL show a timeline of annotated sections and SHALL highlight the selected practice section.
4. THE system SHALL explain the recommendation in plain language grounded in observed evidence, for example naming the movement and how many times it occurred late.
5. THE primary action SHALL be "Practice this section"; secondary actions SHALL be replay, view leaderboard and choose another choreography.
6. IF tracking evidence is insufficient THEN the system SHALL recommend a camera setup adjustment and a retry, and SHALL NOT invent a dance correction from missing data.
7. IF every section is strong THEN the system SHALL offer an optional refinement section or a replay and SHALL state that no major error was found.

---

## Requirement 11 — Practice recommendation

**User story:** As a student, I want the app to pick the section I most need to work on, so that I practise the thing that is actually wrong.

### Acceptance criteria

1. WHEN an attempt is finalized THEN the server SHALL recompute per-section summaries from submitted observations using the shared scorer.
2. THE server SHALL rank sections by supported error severity and recurrence, subject to sufficient tracking coverage for that section.
3. THE selected section SHALL be an existing annotated musical section, typically one or two eight-count phrases, and SHALL NOT be an arbitrary video boundary.
4. THE assignment SHALL record source attempt, section, focus error code, baseline metric, required repetitions, and the content, scoring and model versions.
5. IF no reliable error exists THEN the server SHALL return a typed alternative — camera recalibration, whole-routine replay, or optional refinement — and SHALL NOT manufacture a diagnosis.
6. THE recommendation SHALL be deterministic for a given attempt and configuration version.
7. WHERE the client is offline THE client SHALL produce a provisional recommendation using the same selection rules, label it pending sync, and SHALL replace it with the server's result after upload.

---

## Requirement 12 — Targeted drill

**User story:** As a student, I want to loop the weak section with a clear instruction, so that I can fix one thing through repetition.

### Acceptance criteria

1. WHEN a drill starts THEN the system SHALL load the server's assignment including content version, section boundaries, focus error, instructions and baseline evidence.
2. THE drill SHALL show a short preview and SHALL lead into the section using its musical count.
3. THE default drill SHALL be three measured repetitions at normal speed.
4. WHERE slow practice is enabled it SHALL use 0.75× playback, SHALL be offered only after audio and video synchronization at that rate is verified on the reference device, and SHALL be followed by a normal-speed check before any improvement comparison.
5. EACH repetition SHALL have its own count-in and timestamp origin, and the system SHALL flush pending observations between repetitions so that poses from one repetition cannot affect the next.
6. THE system SHALL treat a drill as complete when the required repetitions have sufficient tracking coverage to be assessed, and completion SHALL NOT imply mastery.
7. IF performance remains weak THEN the system SHALL save the completed drill, offer another attempt, and SHALL NOT claim improvement.
8. THE pair `(assignment, repetitionIndex)` SHALL be unique so that a retry cannot duplicate a completion.

---

## Requirement 13 — Drill result, replay and progress

**User story:** As a student, I want to see whether the drill changed anything and then dance the whole routine again, so that the loop closes.

### Acceptance criteria

1. THE system SHALL show the focus metric before and after only where both observations used comparable playback speed, model version, content version and scoring version.
2. THE system SHALL state the observed change in concrete terms, such as a reduction in late events, and SHALL NOT generalise it to overall dance proficiency.
3. THE primary action after a drill result SHALL be "Replay choreography".
4. THE system SHALL save repetitions and assignment completion exactly once, and SHALL update progress exactly once per completion.
5. THE progress view SHALL show recent attempts, completed drills, best score per routine, and movement and timing trends filtered to compatible versions.
6. THE system SHALL NOT present a single improvement percentage that mixes routines, difficulties or incompatible versions.
7. Drill scores SHALL NOT be eligible for full-run leaderboards.

---

## Requirement 14 — Leaderboard integrity

**User story:** As a student on a leaderboard, I want the ranking to compare like with like, so that a place reflects dancing rather than a settings choice.

### Acceptance criteria

1. THE board key SHALL comprise choreography content version, difficulty, scoring version and a compatible model cohort.
2. THE system SHALL combine different inference models in one cohort only where validation demonstrates comparable scoring and an explicit compatibility group permits it.
3. THE system SHALL accept only normal-speed, completed, sufficiently observed ranked attempts; paused, slowed, sought, offline-started, interrupted and drill attempts SHALL be excluded.
4. THE pair `(boardKey, user)` SHALL be unique, holding that user's best eligible attempt.
5. WHEN two finalizations for the same user and board arrive concurrently THEN the personal-best update SHALL be atomic and SHALL converge on the higher eligible score.
6. THE system SHALL order by total score descending, SHALL display a shared rank for equal scores, and SHALL paginate deterministically using achievement timestamp and a stable identifier.
7. WHEN no eligible score exists THEN the system SHALL show an honest empty state rather than placeholder entries.
8. THE documentation SHALL describe this as a casual leaderboard and SHALL NOT claim the client pose trace is proven authentic; request limits and plausibility checks SHALL be applied.

---

## Requirement 15 — Settings, privacy and deletion

**User story:** As a student, I want control over my data and what others can see, so that I can use the app without exposing myself.

### Acceptance criteria

1. THE settings screen SHALL provide mirror preference, optional skeleton overlay, audio cues, download management, profile editing, leaderboard visibility, sign-out and account deletion.
2. WHEN a user requests deletion THEN a documented server workflow SHALL remove their personal results, drill history, progress and leaderboard records.
3. THE server SHALL derive the acting user from the authenticated session and SHALL NOT accept client-supplied ownership as authority.
4. EVERY private endpoint SHALL verify ownership of the referenced attempt, assignment or profile and SHALL reject cross-account access.
5. THE system SHALL store timestamps in UTC and SHALL apply the profile timezone only for display.
6. THE system SHALL retain raw pose traces only as long as needed for recomputation and debugging under a documented retention policy, and SHALL keep aggregate results thereafter.
7. THE system SHALL NOT log authentication tokens or pose payloads.

---

## Requirement 16 — State integrity and error recovery

**User story:** As a student, I want the app to behave predictably when something breaks, so that I am never stuck on a spinner or shown a score that was not earned.

### Acceptance criteria

1. THE gameplay state machine SHALL be `selecting → downloading → settingUp → countingIn → running → finishing → results → preparingDrill → drilling → drillResults`, with side states `pausedPractice`, `trackingLost`, `recoverableError` and `aborted`.
2. THE upload state machine SHALL be `local → queued → uploading → awaitingFinalization → synced`, and SHALL distinguish retryable network failure, authentication required, incompatible content and permanently rejected ranked eligibility.
3. EACH transition SHALL define ownership of camera, media player, inference session and timers, and leaving a session SHALL dispose each resource exactly once.
4. EACH run and each drill repetition SHALL carry a generation token, and the system SHALL ignore callbacks from an earlier generation.
5. WHEN a result exists locally THEN the system SHALL present it rather than blocking on a pending network operation.
6. AN incomplete run SHALL remain incomplete and SHALL NOT create a personal best.

---

## Requirement 17 — Performance and reliability

**User story:** As a student on a mid-range Android phone, I want the game to keep up with me, so that the feedback is about my dancing and not about the device.

### Acceptance criteria

1. THE system SHALL sustain a pose processing rate of at least 15 Hz on the nominated reference device in a release build; the measured distribution SHALL be recorded.
2. IF the sustained rate falls low enough that event timing becomes unreliable THEN the system SHALL degrade visibly and widen tolerances or mark the run unranked.
3. THE p95 capture-to-feedback delay SHALL be below 200 ms as an initial target, measured and recorded; timing calculations SHALL continue to use capture timestamps regardless.
4. THE system SHALL run ten minutes of repeated attempts without crash, unbounded memory growth or a growing frame queue.
5. THE system SHALL recover a known injected timing offset from a recorded trace within a documented tolerance derived from the capture rate.
6. EVERY recorded performance result SHALL carry device model, OS version, app build, model hash, delegate, measured frame rate and thermal condition.
7. THE project SHALL NOT restate performance figures inherited from the original project's documentation.

---

## Requirement 18 — Deployment and reproducibility

**User story:** As a judge, I want to install the app, reach a live backend and reproduce the build, so that I can verify the project works.

### Acceptance criteria

1. THE backend SHALL be deployed to a hosting target that supports the locked Serverpod version, database migrations, secrets and email delivery.
2. THE README SHALL state exact Flutter, Dart, Serverpod, ExecuTorch runtime and model-export versions, and SHALL include local startup, migration, seed and client-generation steps.
3. THE README SHALL document how a physical phone reaches a local backend, how to fetch verified model and media assets from a clean checkout, and Android build and install steps with device requirements and known limitations.
4. THE repository SHALL contain no credential in source, example configuration, committed lockfile or log output.
5. THE system SHALL emit structured server logs carrying attempt identifier, error category, duration and finalization outcome.
6. THE project SHALL retain prior model, content and scoring artifacts needed to serve already-submitted attempts, and deploying a new scorer SHALL NOT alter stored historical results or merge incompatible leaderboard cohorts.
7. AN installable release build and its matching source revision SHALL be recorded together.

---

## Requirement 19 — Competition submission

**User story:** As the entrant, I want every required submission artifact ready before the deadline, so that the entry is not failed on a technicality.

### Acceptance criteria

1. THE submission SHALL be complete before 14 October 2026 at 23:59 CEST; no extension exists.
2. THE project SHALL remain installable and the backend reachable, free of charge and without restriction, through 20 October 2026 at 17:00 CEST.
3. THE repository SHALL contain all source, assets and instructions required to make the project functional, and WHERE it is private it SHALL be shared with the three Serverpod judging addresses recorded in `docs/rules_serverpod_hackathon.md`.
4. THE demonstration video SHALL be under two minutes, publicly visible on YouTube or Vimeo, SHALL show the project running on the target device, and SHALL NOT contain third-party trade marks or copyrighted music or other material without permission.
5. THE video SHALL show real tracking, real server writes and real leaderboard state, and SHALL NOT imply an unobserved improvement or a fake continuous run.
6. THE text description SHALL explain features and how the project was built, SHALL include build and run instructions, and SHALL disclose the AI coding tools and model components used.
7. THE submission SHALL include judging account credentials in the private testing instructions rather than in public source.
8. THE project SHALL be newly created during the submission period; commit history SHALL begin on or after 15 September 2026 17:30 CEST.
9. THE entrant SHALL submit one feedback submission containing actionable comments on the Serverpod SDKs, App Studio or documentation during the feedback period.

---

## Out of scope

Instructor accounts, live multiplayer, chat, payments, user-uploaded choreography, a choreography editor, motion-capture avatars, large music catalogs, automated beat detection, iOS, Flutter web, browser inference and desktop gameplay. No LLM is used to phrase feedback; evidence-based templates are sufficient.

## Deferred with a named trigger

- iOS: after the Android workflow is verified end to end.
- Slow (0.75×) practice: only after audio/video synchronization is measured as stable at that rate (Requirement 12.4).
- Hardware acceleration beyond XNNPACK CPU: only after a correctness baseline exists and a measured problem justifies it (Requirement 5).
