BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_libraries" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "libraryVersion" bigint NOT NULL,
    "lastSyncAt" timestamp without time zone NOT NULL,
    "lastModifiedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "user_library_user_idx" ON "user_libraries" USING btree ("userId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "user_libraries"
    ADD CONSTRAINT "user_libraries_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR musheet
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('musheet', '20251216161146631', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251216161146631', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
