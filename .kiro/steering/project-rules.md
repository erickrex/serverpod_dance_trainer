# Project rules — Serverpod Dance Trainer

These apply to every change in this repository. They exist because each one has a known failure mode behind it.

## Never fake a measurement — in shipped code. Mocks are fine as tracked test doubles.

**In the app that ships, and in any endpoint that serves a real request:** no mock keypoint generator, no synthetic pose path, no fallback that feeds reference poses in as student poses, no canned response standing in for a database query. If inference fails, stop scoring and say so. The original project shipped `generateMockKeypoints()` and a pre-computed fallback; a judging criterion here is literally "nothing critical is faked" (30% weight, Stage One eligibility), and a run that silently scores from reference data is the worst possible bug because it looks like success.

**In tests, and in scaffolding written ahead of a dependency that isn't available yet (no phone, no credentialed Postgres):** a test double is normal and expected — a `FakePoseEngine` returning fixed landmarks so the gameplay state machine can be tested without a device, a stub Serverpod service class so the Flutter side can be written before the backend is reachable. This is how the toolchain gap gets worked around productively rather than by writing untested, unverifiable code and hoping.

The line between the two is enforced, not just described:

- Every stand-in is named starting with `Stub` or `Fake` (e.g. `StubPoseEngine`, `FakeAttemptRepository`) and carries a `// STUB(<task-id>): <what real thing replaces this, and what task closes the gap>` comment.
- A stub's constructor or factory is never reachable from the app's or server's real bootstrap/wiring code — only from tests and from an explicitly separate "dev harness" entry point that cannot be the one built for release.
- `docs/toolchain_status.md` and the relevant task in `tasks.md` record every stub introduced and what unblocks replacing it with the real thing. A stub with no recorded replacement path is a bug, not scaffolding.
- Before any release, submission or demo-video build, every `Stub`/`Fake` class must be grep-checked out of the shipped target's dependency graph. A stub reachable from `main()` in a release build is exactly the failure this rule exists to prevent, whichever name it's given.

A missing landmark is `LandmarkValidity.absent`, never `x: 0, y: 0`. A missing measurement is never an angle of zero. This part is unconditional — it's a data-representation rule, not a "we don't have the dependency yet" rule, and it applies inside stubs too: a `StubPoseEngine` must still emit real `LandmarkValidity` values, not zeros standing in for "I haven't wired the real one yet."

## Coverage travels with every score

Any movement or timing average shown to a user or returned by an endpoint carries its tracking coverage. Below the configured gate, suppress the overall judgment and mark the run unranked. Attribute the cause to observation, not to the student — "step back into view", not "you missed 40% of the moves".

## Source content is immutable

The six files in `content/source/` are archival. Annotations, corrections and exclusion intervals go in versioned sidecars. Nothing regenerates or overwrites the original MP3, MP4 or JSON bytes. Do not edit the source JSON to fix a tracking problem.

## Time comes from the camera, never from a counter

Dance timestamps derive from camera capture time mapped through the playback anchor into content time. Never from processed-frame count, never from inference completion time. Pause, seek, loop and rate change start a new segment and flush pending observations.

## The domain package stays pure

`packages/dance_domain` imports no Flutter, no FFI, no Serverpod. Scoring is a pure function. Generated transport models are mapped to domain types at the boundary; domain types never carry Serverpod annotations. CI enforces this — if you need to relax it, you have found a design problem, not a build problem.

## Versions are immutable and comparisons are gated

Content versions, scoring configurations and model identities are immutable once published. A leaderboard cohort is keyed by their combination. Never compare two attempts, or show a before/after, across incompatible versions or playback speeds. Deploying a new scorer must not alter stored historical results.

## The server owns the saved score

Client scoring is provisional and exists for responsiveness. The server recomputes from submitted observations with the referenced configuration and never accepts a client-supplied total. Ownership is derived from the session, never from a client-supplied user field.

## Don't claim what 2D landmarks cannot see

Do not score partner connection, foot pressure, weight distribution, precise foot contact, toe direction or subtle 3D hip rotation. Mark sections that depend on them unscorable instead.

## Don't inherit the old project's numbers

Performance figures, accuracy claims and input dimensions from Bacha Trainer's README and filenames are not measurements of this system. The old tree contains conflicting 192- and 256-pixel input assumptions and both a test-network and a trained-model exporter. Record what you measured, on which device, with which model hash.

## Scratch and secrets

No credential in source, example config, lockfile or log. Never log tokens or pose payloads. Keep probe scripts and build logs out of the repository tree.
