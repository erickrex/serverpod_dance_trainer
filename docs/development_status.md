# Development status

The project is a development prototype. This audit distinguishes implemented code from the broader specification and from device acceptance. A checked implementation task does not complete its phase's physical-device exit criterion.

| Area and specification tasks | Implemented and host-verifiable | Remaining work |
|---|---|---|
| Foundation, 0.1–0.8 | Git/LFS repository, pinned workspace, local secret generation, source checksums, domain boundary check, CI definition | Hosted CI execution and production configuration |
| Pose adapter, 1.1–1.10 | Real ExecuTorch model, CameraX bridge, absence detection, bounded inference, mirror and aspect restoration checks | Reference exporter parity, phone timing, camera orientation and sustained throughput; select two devices |
| Content, 2.1–2.7 | Development compiler, source-derived pose checkpoints and exclusions, archived immutable bundles, deterministic rebuilds, recorded-pose fidelity checks | Reviewed musical annotations, general manifest-driven import and registration, explicit schema-v2 import validation, musical alignment tests |
| Scoring, 2.8–2.16 | Normalization, bounded single-use matching, coverage gates, per-section scores, known-offset recorded-fixture tests | Trajectory features, calibrated timing, typed movement corrections with cooldown, learner fixtures and frozen configuration |
| Accounts, 3.2–3.5 | Email auth and SMTP transport, owned profile updates, account deletion including auth identities and stale-token rejection | Production email acceptance, richer onboarding and avatar/experience fields |
| Acquisition and gameplay, 3.6–3.11 | Verified video/model downloads, download management, camera setup and development run flow | Persisted catalog for fully offline browsing/start, silhouette/overlay, musical count-in, richer live feedback, interrupted playback resumption and phone trials |
| Persistence, 3.12–3.21 | Server tickets, durable per-account SQLite evidence, immutable completion, acknowledged-chunk resumption, automatic backoff, isolated queue failures, local completed-result recovery, server recomputation, concurrent submission tests | Real app-kill/auth-refresh/network recovery acceptance on Android; richer result metrics and personal-best presentation |
| Practice, 4.1–4.11 | Owned recommendations and assignments, three distinct measured repetitions, coverage gate, idempotent completion, shared provisional recommendations | Musical section semantics, drill focus-metric comparison, loop/reset device tests and optional slow playback |
| Progress and settings, 5.1–5.10 | Opt-in board, cursor-paginated history, score changes restricted to compatible attempts, profile and account controls, download management | Current-user rank and board pagination, expanded trend views, preference persistence; ranked acceptance awaits reviewed content |
| Retention and operations, 5.11, 7.1–7.4 | Immediate completed-pose cleanup, abandoned-evidence retention job, per-account request and attempt limits, readiness RPC, Docker/CI build definitions, explicit release signing and deployment procedure | Ingress limits and operational monitoring in deployment, production restore rehearsal, hosted Docker build and signed release validation |
| Learner/device acceptance and submission, phases 6–7 | Testable implementation and documented release procedure | Device and learner trials, publishable choreography, scoring/content freeze, deployment and submission materials |

## Recovery behavior

A completed run is marked durable before stopping platform resources. The local copy contains its original catalog bundle, so its provisional result can be reconstructed after restart without a network connection. The server's acknowledged chunk position controls resumed uploads, including when the original acknowledgement was lost. Concurrent sync actions share one upload. A failure leaves that run pending while the queue continues with other runs.

An interrupted run is visible and can be discarded, but must restart to produce a complete performance. This implementation does not resume choreography halfway through a run. Automatic retries run while the signed-in home screen is alive and resume when it is opened again; there is no Android background service.

History compares only matching routine, section, mode, content, model, scoring version and playback speed with sufficient tracking. It reports point differences and both attempts' coverage. It does not label a point increase as proven learning. Pending results stay provisional until acknowledged.

## Test doubles

`FakeTrainingClient` and `FakeAccountRepository` live only in `dance_trainer_flutter/test/repository_test.dart`, tracked under task 3.16. They inject lost responses and account changes around a real SQLite database. Production uses the generated Serverpod client and session manager. PostgreSQL integration tests separately exercise real transactions, ownership, deletion, scoring and concurrency. The doubles require no replacement in production because they are never wired there.

See [verification.md](verification.md) for the executed checks and [operations.md](operations.md) for retention, upgrades and deployment.
