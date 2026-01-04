BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "team_annotations" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "instrument_scores" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "instrument_scores" (
    "id" bigserial PRIMARY KEY,
    "scoreId" bigint NOT NULL,
    "instrumentType" text NOT NULL,
    "customInstrument" text,
    "pdfHash" text,
    "orderIndex" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone,
    "version" bigint NOT NULL,
    "syncStatus" text,
    "annotationsJson" text
);

-- Indexes
CREATE INDEX "instrument_score_idx" ON "instrument_scores" USING btree ("scoreId");
CREATE UNIQUE INDEX "instrument_score_unique" ON "instrument_scores" USING btree ("scoreId", "instrumentType", "customInstrument");
CREATE INDEX "instrument_score_version_idx" ON "instrument_scores" USING btree ("scoreId", "version");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "team_instrument_scores" (
    "id" bigserial PRIMARY KEY,
    "teamScoreId" bigint NOT NULL,
    "instrumentType" text NOT NULL,
    "customInstrument" text,
    "pdfHash" text,
    "orderIndex" bigint NOT NULL,
    "annotationsJson" text,
    "sourceInstrumentScoreId" bigint,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone,
    "version" bigint NOT NULL,
    "syncStatus" text
);

-- Indexes
CREATE INDEX "team_instrument_score_idx" ON "team_instrument_scores" USING btree ("teamScoreId");
CREATE UNIQUE INDEX "team_instrument_score_unique" ON "team_instrument_scores" USING btree ("teamScoreId", "instrumentType", "customInstrument");
CREATE INDEX "team_instrument_score_version_idx" ON "team_instrument_scores" USING btree ("teamScoreId", "version");

--
-- ACTION DROP TABLE
--
DROP TABLE "team_scores" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "team_scores" (
    "id" bigserial PRIMARY KEY,
    "teamId" bigint NOT NULL,
    "title" text NOT NULL,
    "composer" text,
    "bpm" bigint,
    "createdById" bigint NOT NULL,
    "sourceScoreId" bigint,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone,
    "version" bigint NOT NULL,
    "syncStatus" text
);

-- Indexes
CREATE INDEX "team_score_team_idx" ON "team_scores" USING btree ("teamId");
CREATE UNIQUE INDEX "team_score_unique_title_composer" ON "team_scores" USING btree ("teamId", "title", "composer");
CREATE INDEX "team_score_version_idx" ON "team_scores" USING btree ("teamId", "version");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "team_setlist_scores" (
    "id" bigserial PRIMARY KEY,
    "teamSetlistId" bigint NOT NULL,
    "teamScoreId" bigint NOT NULL,
    "orderIndex" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone,
    "version" bigint NOT NULL,
    "syncStatus" text
);

-- Indexes
CREATE INDEX "team_setlist_score_setlist_idx" ON "team_setlist_scores" USING btree ("teamSetlistId");
CREATE INDEX "team_setlist_score_score_idx" ON "team_setlist_scores" USING btree ("teamScoreId");
CREATE UNIQUE INDEX "team_setlist_score_unique" ON "team_setlist_scores" USING btree ("teamSetlistId", "teamScoreId");

--
-- ACTION DROP TABLE
--
DROP TABLE "team_setlists" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "team_setlists" (
    "id" bigserial PRIMARY KEY,
    "teamId" bigint NOT NULL,
    "name" text NOT NULL,
    "description" text,
    "createdById" bigint NOT NULL,
    "sourceSetlistId" bigint,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone,
    "version" bigint NOT NULL,
    "syncStatus" text
);

-- Indexes
CREATE INDEX "team_setlist_team_idx" ON "team_setlists" USING btree ("teamId");
CREATE UNIQUE INDEX "team_setlist_unique_name" ON "team_setlists" USING btree ("teamId", "name");
CREATE INDEX "team_setlist_version_idx" ON "team_setlists" USING btree ("teamId", "version");

--
-- ACTION DROP TABLE
--
DROP TABLE "teams" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "teams" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text,
    "createdById" bigint NOT NULL,
    "teamLibraryVersion" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "team_name_idx" ON "teams" USING btree ("name");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "instrument_scores"
    ADD CONSTRAINT "instrument_scores_fk_0"
    FOREIGN KEY("scoreId")
    REFERENCES "scores"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "team_instrument_scores"
    ADD CONSTRAINT "team_instrument_scores_fk_0"
    FOREIGN KEY("teamScoreId")
    REFERENCES "team_scores"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "team_scores"
    ADD CONSTRAINT "team_scores_fk_0"
    FOREIGN KEY("teamId")
    REFERENCES "teams"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "team_scores"
    ADD CONSTRAINT "team_scores_fk_1"
    FOREIGN KEY("createdById")
    REFERENCES "users"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "team_setlist_scores"
    ADD CONSTRAINT "team_setlist_scores_fk_0"
    FOREIGN KEY("teamSetlistId")
    REFERENCES "team_setlists"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "team_setlist_scores"
    ADD CONSTRAINT "team_setlist_scores_fk_1"
    FOREIGN KEY("teamScoreId")
    REFERENCES "team_scores"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "team_setlists"
    ADD CONSTRAINT "team_setlists_fk_0"
    FOREIGN KEY("teamId")
    REFERENCES "teams"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "team_setlists"
    ADD CONSTRAINT "team_setlists_fk_1"
    FOREIGN KEY("createdById")
    REFERENCES "users"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "teams"
    ADD CONSTRAINT "teams_fk_0"
    FOREIGN KEY("createdById")
    REFERENCES "users"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR musheet
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('musheet', '20251230131245296', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251230131245296', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
