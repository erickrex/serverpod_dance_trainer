BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "learner_profile" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "displayName" text NOT NULL,
    "leaderboardVisible" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "learner_user_unique" ON "learner_profile" USING btree ("userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "practice_assignment" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "sourceAttemptId" bigint NOT NULL,
    "routineId" text NOT NULL,
    "contentVersion" text NOT NULL,
    "sectionId" text NOT NULL,
    "completedRepetitions" bigint NOT NULL,
    "completed" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "assignment_source_unique" ON "practice_assignment" USING btree ("userId", "sourceAttemptId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "practice_repetition" (
    "id" bigserial PRIMARY KEY,
    "assignmentId" bigint NOT NULL,
    "attemptId" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "repetition_attempt_unique" ON "practice_repetition" USING btree ("attemptId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "training_attempt" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "clientUuid" text NOT NULL,
    "routineId" text NOT NULL,
    "contentVersion" text NOT NULL,
    "modelVersion" text NOT NULL,
    "mode" text NOT NULL,
    "sectionId" text,
    "ticket" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "status" text NOT NULL,
    "nextChunk" bigint NOT NULL,
    "payloadBytes" bigint NOT NULL,
    "resultJson" text
);

-- Indexes
CREATE UNIQUE INDEX "attempt_user_uuid_unique" ON "training_attempt" USING btree ("userId", "clientUuid");
CREATE INDEX "attempt_history_idx" ON "training_attempt" USING btree ("userId", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "training_best" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "boardKey" text NOT NULL,
    "attemptId" bigint NOT NULL,
    "score" bigint NOT NULL,
    "achievedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "best_user_board_unique" ON "training_best" USING btree ("userId", "boardKey");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "training_chunk" (
    "id" bigserial PRIMARY KEY,
    "attemptId" bigint NOT NULL,
    "sequence" bigint NOT NULL,
    "digest" text NOT NULL,
    "payloadJson" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "chunk_sequence_unique" ON "training_chunk" USING btree ("attemptId", "sequence");


--
-- MIGRATION VERSION FOR dance_trainer
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('dance_trainer', '20260919111633201', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260919111633201', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();


COMMIT;
