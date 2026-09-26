# Serverpod Dance Trainer

An Android Flutter app with camera pose tracking, a shared Dart scorer, and Serverpod persistence. Choose a routine, dance with the instructor video, save a result, and repeat a recommended section.

The implementation now includes real inference, authenticated training endpoints, local evidence storage and retry, server scoring, history, profiles, practice assignments, and an opt-in leaderboard. It is a **development build**. Both routines remain unreviewed and unranked. Physical-device camera timing and sustained performance have not been validated. The broader specification also includes work that remains unfinished; see [verification](docs/verification.md).

Completed runs can recover after a restart, resume their uploads and show provisional results offline. History supports older pages and comparisons between compatible attempts. Profile settings include account deletion and download management. See the [development audit](docs/development_status.md) for the remaining specification work.

## Toolchain

Large assets are kept locally and are not included in this repository: the six
original MP3, MP4 and pose JSON files under `content/source/`, and model weights
such as `content/models/yolov8n-pose_xnnpack.pte`. Before running training,
content compilation, media-dependent tests or the server image build, supply
these files at their original paths. See `content/manifests/source_inventory.json`
for the source inventory and checksums, and [model provenance](content/models/README.md)
for the model source and checksum. Cloning this repository alone does not provide
a runnable training experience. Small compiled bundles and asset metadata are included.

Use Flutter **3.38.9**, Dart **3.10.8**, Serverpod and Serverpod CLI **3.4.13**, JDK 17, and the Android SDK. Android training requires a front camera and API 24 or newer. The current build targets arm64. Native host inference tests require CMake, Ninja, a C++ compiler, and FFmpeg.

```bash
flutter pub get
dart pub global activate serverpod_cli 3.4.13
dart run scripts/configure_local.dart
bash scripts/verify_content.sh
```

`configure_local.dart` creates ignored development/test secrets and Compose environment values. It preserves existing configuration. Production secrets and deployment hosts must be configured separately. Keep `config/passwords.yaml`, `.env`, and signing keys out of version control.

## Start the backend

From the repository root, start PostgreSQL. This uses ports 8090 and 9090 and does not require access to a shared PostgreSQL instance on 5432.

```bash
docker compose -f dance_trainer_server/docker-compose.yaml up -d
```

Configure SMTP before signing up or resetting a password. Missing configuration produces an error; verification codes are never printed by the app. For local delivery, run an SMTP capture service such as Mailpit:

```bash
docker run --rm -p 127.0.0.1:1025:1025 -p 127.0.0.1:8025:8025 axllent/mailpit
```

In a separate terminal:

```bash
export DANCE_SMTP_HOST=127.0.0.1
export DANCE_SMTP_PORT=1025
export DANCE_SMTP_FROM=trainer@example.test
cd dance_trainer_server
dart run bin/main.dart --apply-migrations
```

Open the capture service at `http://localhost:8025` to retrieve local verification emails. For a real provider, set `DANCE_SMTP_HOST`, `DANCE_SMTP_PORT`, `DANCE_SMTP_FROM`, and, when required, `DANCE_SMTP_USER` and `DANCE_SMTP_PASSWORD`. Set `DANCE_SMTP_SSL=true` for implicit TLS. Unencrypted SMTP is accepted only on loopback.

The API listens on 8080 and assets on 8082. Database migrations run before serving requests. To regenerate transport code after changing endpoints or models:

```bash
cd dance_trainer_server
serverpod generate
```

## Run on Android

With a USB-connected device, forward the API and asset ports:

```bash
adb reverse tcp:8080 tcp:8080
adb reverse tcp:8082 tcp:8082
cd dance_trainer_flutter
flutter run --dart-define=SERVER_URL=http://127.0.0.1:8080/ --dart-define=ASSET_URL=http://127.0.0.1:8082/
```

Alternatively, use the development computer's reachable LAN address in both defines. Create an account through the sign-in screen and use the emailed code. The app downloads and verifies the instructor video and the trained pose model before starting. Hold your full body in view for setup, then start the countdown. Leaving the app stops the run. A completed run retains its observations locally if upload fails. Returning to the home screen resumes automatic retries with the original account; the sync button retries immediately. History shows pending and interrupted local runs. Interrupted runs must restart.

Only Android has a camera bridge. Other platforms cannot start a training run. Development HTTP is enabled only in the Android debug manifest. Production builds need HTTPS endpoints and a release signing configuration.

Release builds require the four signing environment variables described in [operations](docs/operations.md). Missing signing credentials fail the release build instead of producing a debug-signed release.

```bash
flutter build apk --debug --target-platform android-arm64
```

## Content and scoring

`content/source` contains six immutable archival files. The checksum script verifies all six. Do not overwrite these files. The extractor rejects archival destinations, existing outputs, and path traversal.

```bash
dart run tools/content_pipeline/compile.dart
```

The compiler reads the actual video dimensions and source sampling rates, excludes unreliable tracking intervals, and produces development pose checkpoints and sidecars. These are not human-reviewed choreography or beat annotations. The app uses each MP4's own audio to keep instructor playback on one timeline; the separate MP3 files remain archived.

Previous bundles remain in `content/compiled/versions`. The server resolves queued attempts against their original version. Preserve these files in deployments; the compiler rejects changed bytes under an existing version.

The scorer compares joint angles, limb directions, and body-scaled positions. A frame can match at most one checkpoint. Missing measurements reduce coverage; wholly mismatched movement earns no timing credit. Overall judgment is suppressed below the coverage gate. The server recomputes saved scores from observations, and never accepts a client total. Neither development routine can enter the leaderboard.

The pinned model is recorded in [model provenance](content/models/README.md). Its upstream license is AGPL-3.0. The preserved routine media also has unresolved publication permissions; see [third-party notices](THIRD_PARTY_NOTICES.md). This project has not been published or deployed by this work.

## Verification

Run with PostgreSQL available on the test port:

```bash
bash scripts/verify_content.sh
bash scripts/check_domain_boundary.sh
dart analyze
(cd packages/dance_domain && dart test)
(cd dance_trainer_server && dart test --concurrency=1)
(cd dance_trainer_flutter && flutter test)
python3 -m unittest discover -s tools/content_pipeline/pose_extract/tests
```

The Flutter suite loads the actual model and decodes a frame from the archived video. It tests detected landmarks, mirrored output, and an empty image. It requires the locally supplied model/media files described above. No fake pose generator is connected to app bootstrap.

A GitHub Actions workflow is kept locally under `.github/workflows/` and is excluded from this repository until it is ready to publish. Run the commands above for local verification. Local results and remaining limitations are in [docs/verification.md](docs/verification.md).

The SQLite recovery tests use test-only transport and account doubles to inject failures. PostgreSQL tests separately verify real ownership, deletion, idempotency and concurrent transactions. The unpublished workflow also defines checks for generated transport code, deterministic content, the server Docker build and an Android debug build.

## Server image

Build from the repository root so the shared domain and runtime content are included:

```bash
docker build -f dance_trainer_server/Dockerfile -t dance-trainer-server .
```

The image uses Dart 3.10.8 and includes the model, compiled bundles and source media. It excludes passwords and runs as an unprivileged user. Supply runtime configuration, SMTP environment variables and a reachable database when starting it. The build's isolated Dart workspace has been compiled locally; a Docker image build still requires a Docker daemon.

Deployment, readiness checks, migration recovery, account deletion and pose-data retention are documented in [operations](docs/operations.md).

## Project map

| Path | Purpose |
|---|---|
| `packages/dance_domain` | Pure scoring and evidence validation |
| `dance_trainer_server` | Authenticated persistence, scoring, SMTP, assets and migrations |
| `dance_trainer_client` | Generated API transport |
| `dance_trainer_flutter` | Android training flow and durable upload queue |
| `tools/content_pipeline` | Development content compiler and extraction tools |
| `.kiro/specs/serverpod-dance-trainer` | Broader requirements, design and task backlog |
| `.kiro/steering/project-rules.md` | Measurement, content and scoring rules |
| `docs/content_audit.md` | Source-media audit |
