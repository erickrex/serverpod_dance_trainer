# Build from the workspace root: docker build -f dance_trainer_server/Dockerfile .
FROM dart:3.10.8 AS build
WORKDIR /app
COPY pubspec.lock .
COPY dance_trainer_server/pubspec.yaml dance_trainer_server/pubspec.yaml
COPY packages/dance_domain/pubspec.yaml packages/dance_domain/pubspec.yaml
RUN printf '%s\n' 'name: serverpod_dance_trainer_build' 'publish_to: none' \
  'environment:' '  sdk: ^3.10.0' 'workspace:' \
  '  - dance_trainer_server' '  - packages/dance_domain' > pubspec.yaml
RUN dart pub get
COPY packages/dance_domain/lib packages/dance_domain/lib
COPY dance_trainer_server/lib dance_trainer_server/lib
COPY dance_trainer_server/bin dance_trainer_server/bin
WORKDIR /app/dance_trainer_server
RUN dart compile exe bin/main.dart -o /app/server

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/* && useradd --system --uid 10001 trainer
WORKDIR /app
COPY --from=build /runtime/ /
COPY --from=build /app/server ./server
COPY dance_trainer_server/config/development.yaml config/development.yaml
COPY dance_trainer_server/config/staging.yaml config/staging.yaml
COPY dance_trainer_server/config/production.yaml config/production.yaml
COPY dance_trainer_server/migrations migrations
COPY dance_trainer_server/web web
COPY content/compiled content/compiled
COPY content/models content/models
COPY content/source content/source
COPY dance_trainer_server/lib/src/generated/protocol.yaml lib/src/generated/protocol.yaml
USER trainer
ENV runmode=production
EXPOSE 8080 8081 8082
# Mount config/passwords.yaml at runtime; it is never included in image layers.
ENTRYPOINT ["sh", "-c", "exec ./server --mode=$runmode --apply-migrations"]
