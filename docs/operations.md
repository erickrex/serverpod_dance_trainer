# Deployment and data operations

This is a deployment procedure for the current development build. No production environment or release signing key has been provisioned.

## Build and configure

1. Check out the intended revision with Git LFS installed and run `git lfs pull`. Verify `bash scripts/verify_content.sh`, run the test suites, and compile the bundles with `dart run tools/content_pipeline/compile.dart`.
2. Build from the repository root with `docker build -f dance_trainer_server/Dockerfile -t dance-trainer-server:REVISION .`. Record the image digest with its Git revision and migration version. CI defines this build; this WSL host has no working Docker daemon.
3. Copy `dance_trainer_server/config/production.yaml` to private deployment configuration. Set the API and asset public hosts, HTTPS ports, and database connection. Keep PostgreSQL and Insights private. Set a bounded database connection count appropriate to the database and replica count.
4. Supply a private `config/passwords.yaml` with a `production` map containing `database`, `serviceSecret`, `emailSecretHashPepper`, `jwtHmacSha512PrivateKey` and `jwtRefreshTokenHashPepper`. Generate independent secrets using the deployment secret manager. The database value must match the provisioned database user's password. Preserve auth keys and peppers across restarts; replacing them has consequences for existing credentials and sessions.
5. Configure SMTP with `DANCE_SMTP_HOST`, `DANCE_SMTP_PORT`, `DANCE_SMTP_FROM`, and provider credentials in `DANCE_SMTP_USER` and `DANCE_SMTP_PASSWORD`. Set `DANCE_SMTP_SSL=true` for implicit TLS. Do not place credentials in the image, command-line arguments or source control.

An example container invocation, after replacing the private paths and image tag:

```bash
docker run --name dance-trainer --restart unless-stopped \
  --env-file /absolute/private/smtp.env \
  --mount type=bind,src=/absolute/private/production.yaml,dst=/app/config/production.yaml,readonly \
  --mount type=bind,src=/absolute/private/passwords.yaml,dst=/app/config/passwords.yaml,readonly \
  -p 127.0.0.1:8080:8080 -p 127.0.0.1:8082:8082 \
  dance-trainer-server:REVISION
```

Mounted configuration must be readable by container UID 10001. Route public HTTPS traffic through a reverse proxy to API port 8080 and assets port 8082. Preserve MP4 range requests. Limit API request bodies to 512 KiB, and apply ingress connection and request limits, including to invalid or unauthenticated requests. The application quota covers successful authenticated training operations and does not replace ingress controls.

The readiness RPC checks database connectivity, compiled content and model presence:

```bash
curl --fail --silent --show-error \
  -H 'Content-Type: application/json' \
  --data '{"method":"ready"}' http://127.0.0.1:8080/health
```

Expect `"ok"`. Through the public hosts, verify readiness, registration email delivery, password recovery, a saved attempt, and an MP4 byte-range response before distributing a build. A readiness response does not validate SMTP or phone behavior.

## Migrations and rollback

The image entrypoint applies committed migrations before accepting traffic. Before an upgrade, take a PostgreSQL backup or recovery checkpoint, verify restoration in a separate database, and retain the previous image and configuration. For multiple replicas, apply migrations with one instance while the others are stopped, then start the remaining instances.

The current migration adds `training_quota`; it does not remove existing results. Reverting application code while leaving this additive table is possible. Future destructive migrations require a tested restore procedure. Do not automatically run a down migration against a live database. If an upgrade cannot use the existing schema, stop writes and restore the pre-upgrade database with its matching image; account for any writes made since the checkpoint.

## Evidence and account data

- Finalization saves the server result and clears raw chunk payloads in one transaction. Chunk hashes remain to validate retries without retaining the poses.
- Unfinished server attempts and their evidence expire after seven days. A persistent Serverpod future call runs on startup and every six hours. Monitor future-call failures; an outage delays cleanup until service resumes. Each pass processes up to 1,000 owners.
- The phone erases raw observations after the result and any practice completion are acknowledged. Unsynced or interrupted local runs remain visible in History and can be explicitly discarded. Automatic retry waits grow from five seconds to at most five minutes; the home screen checks due work every fifteen seconds. Retries resume after relaunch and require the original account.
- Confirmed account deletion first clears the local queue on the requesting device, then requests removal of the auth user and linked Serverpod identities, sessions, profile, attempts, evidence, practice records, best scores and quotas. A lost response cannot strand local evidence behind a deleted identity. If server deletion is not confirmed, the app reports this and asks the user to retry; it does not claim remote success. Other devices cannot access the deleted account; existing offline data on them is not remotely erased. Database backups follow the deployment backup retention policy and must not be restored into service without replaying subsequent deletions.
- Per-account training operations allow 300 successful requests per minute and 60 new attempts per hour. Evidence remains limited to 256 KiB and 200 observations per chunk, and 6 MiB per attempt. Validation failures do not commit quota increments.

## Content upgrades

The compiler preserves bundles at `content/compiled/versions/ROUTINE/VERSION.json` before replacing the current catalog bundle. Existing version bytes cannot be overwritten. Finalization resolves the attempt's version, so installing a new catalog version does not rescore queued evidence against it. Include the archive in deployment images.

The installed scorer must still support the archived bundle's scoring version. Unsupported versions fail explicitly. A future scorer upgrade needs a versioned scorer implementation or a drain of pending uploads before removing the old implementation. Retain matching model and media artifacts separately when changing them; the current archive stores compiled bundles, not duplicate copies of every media/model version.

## Android release configuration

Debug builds remain available for testing. Release builds require a real signing configuration and fail when it is missing; they no longer use the debug key. Set `DANCE_KEYSTORE_PATH`, `DANCE_KEY_ALIAS`, `DANCE_KEYSTORE_PASSWORD` and `DANCE_KEY_PASSWORD` through the build environment, with the keystore held outside source control. Select the final application ID before creating a distributed release.

```bash
cd dance_trainer_flutter
flutter build apk --release --target-platform android-arm64 \
  --dart-define=SERVER_URL=https://api.YOUR_DOMAIN/ \
  --dart-define=ASSET_URL=https://assets.YOUR_DOMAIN/
```

These are placeholder hosts. Verify the signed build and real camera flow on the nominated devices before distribution. The development routines remain unranked, and media publication permissions and model distribution obligations remain unresolved.

## Serverpod reference

Account deletion follows [working with users](https://docs.serverpod.dev/3.0.0/concepts/authentication/working-with-users). Signatures and cascading relationships were checked against the installed 3.4.13 `AuthUsers` implementation. Cleanup uses the generated future-call dispatcher supplied by that pinned SDK.
