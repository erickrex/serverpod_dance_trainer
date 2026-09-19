# Toolchain status, 19 September 2026

Current checks supersede the earlier claim that this host could not run Serverpod or native inference. See [verification.md](verification.md) for tested behavior and release gaps.

| Tool | Verified status |
|---|---|
| Flutter | 3.38.9 at `/home/rexbox/dev/flutter-dance`; prior installation preserved |
| Dart | 3.10.8, bundled with that Flutter SDK |
| Serverpod CLI | 3.4.13 at `/home/rexbox/.pub-cache/bin/serverpod` |
| PostgreSQL | Isolated test cluster on loopback port 9090, database `dance_trainer_test`; integration tests run against it |
| Shared PostgreSQL | Existing service on 5432 was not modified or used |
| Java | Temurin 17 at `/home/rexbox/dev/dance-android/jdk` |
| Android SDK | `/home/rexbox/dev/dance-android/sdk`, platforms 34–36, build tools, platform tools and NDK installed |
| Native build tools | CMake and Ninja at `/home/rexbox/dev/dance-build-tools/bin`; system GCC/G++ |
| FFmpeg / ffprobe | Used for source dimensions and real-model frame decoding |
| Docker daemon | Unavailable; isolated Dart server build used to verify the image's compilation stage |
| Android debug APK | Built for arm64 at `dance_trainer_flutter/build/app/outputs/flutter-apk/app-debug.apk` |
| Physical Android device | Not connected; no phone performance or camera claims |

For this host:

```bash
export PATH=/home/rexbox/dev/dance-build-tools/bin:/home/rexbox/dev/flutter-dance/bin:/home/rexbox/.pub-cache/bin:$PATH
export JAVA_HOME=/home/rexbox/dev/dance-android/jdk
export ANDROID_HOME=/home/rexbox/dev/dance-android/sdk
```

The temporary test cluster is under `/tmp/dance-fixes/postgres-test` and may disappear after a host reset. For a fresh environment use the Compose and configuration steps in the root README. Build logs and scratch probes are under `/tmp/dance-fixes`, outside source control. The local SMTP probe used a capture process; no test double was added to production code.
