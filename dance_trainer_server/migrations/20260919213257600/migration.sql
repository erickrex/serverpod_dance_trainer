BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "training_quota" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "windowStart" timestamp without time zone NOT NULL,
    "requests" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "quota_user_unique" ON "training_quota" USING btree ("userId");


--
-- MIGRATION VERSION FOR dance_trainer
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('dance_trainer', '20260919213257600', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260919213257600', "timestamp" = now();

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
