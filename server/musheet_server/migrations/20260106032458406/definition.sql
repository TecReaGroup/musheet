BEGIN;

--
-- Class Annotation as table annotations
--
CREATE TABLE "annotations" (
    "id" bigserial PRIMARY KEY,
    "instrumentScoreId" bigint NOT NULL,
    "userId" bigint NOT NULL,
    "pageNumber" bigint NOT NULL,
    "type" text NOT NULL,
    "data" text NOT NULL,
    "positionX" double precision NOT NULL,
    "positionY" double precision NOT NULL,
    "width" double precision,
    "height" double precision,
    "color" text,
    "vectorClock" text,
    "points" text,
    "strokeWidth" double precision,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "version" bigint NOT NULL,
    "syncStatus" text
);

-- Indexes
CREATE INDEX "annotation_inst_score_idx" ON "annotations" USING btree ("instrumentScoreId");
CREATE INDEX "annotation_user_version_idx" ON "annotations" USING btree ("userId", "version");

--
-- Class Application as table applications
--
CREATE TABLE "applications" (
    "id" bigserial PRIMARY KEY,
    "appId" text NOT NULL,
    "name" text NOT NULL,
    "description" text,
    "iconPath" text,
    "isActive" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "app_id_idx" ON "applications" USING btree ("appId");

--
-- Class InstrumentScore as table instrument_scores
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
-- Class Score as table scores
--
CREATE TABLE "scores" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "title" text NOT NULL,
    "composer" text,
    "bpm" bigint,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone,
    "version" bigint NOT NULL,
    "syncStatus" text
);

-- Indexes
CREATE INDEX "score_user_idx" ON "scores" USING btree ("userId");
CREATE INDEX "score_user_updated_idx" ON "scores" USING btree ("userId", "updatedAt");
CREATE UNIQUE INDEX "score_user_title_composer_unique" ON "scores" USING btree ("userId", "title", "composer");
CREATE INDEX "score_user_version_idx" ON "scores" USING btree ("userId", "version");

--
-- Class SetlistScore as table setlist_scores
--
CREATE TABLE "setlist_scores" (
    "id" bigserial PRIMARY KEY,
    "setlistId" bigint NOT NULL,
    "scoreId" bigint NOT NULL,
    "orderIndex" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone,
    "version" bigint NOT NULL,
    "syncStatus" text
);

-- Indexes
CREATE INDEX "setlist_score_idx" ON "setlist_scores" USING btree ("setlistId");
CREATE UNIQUE INDEX "setlist_score_unique" ON "setlist_scores" USING btree ("setlistId", "scoreId");

--
-- Class Setlist as table setlists
--
CREATE TABLE "setlists" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "name" text NOT NULL,
    "description" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone,
    "version" bigint NOT NULL,
    "syncStatus" text
);

-- Indexes
CREATE INDEX "setlist_user_idx" ON "setlists" USING btree ("userId");
CREATE UNIQUE INDEX "setlist_user_name_unique" ON "setlists" USING btree ("userId", "name");
CREATE INDEX "setlist_version_idx" ON "setlists" USING btree ("userId", "version");

--
-- Class TeamInstrumentScore as table team_instrument_scores
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
-- Class TeamMember as table team_members
--
CREATE TABLE "team_members" (
    "id" bigserial PRIMARY KEY,
    "teamId" bigint NOT NULL,
    "userId" bigint NOT NULL,
    "role" text NOT NULL,
    "joinedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "team_member_team_idx" ON "team_members" USING btree ("teamId");
CREATE INDEX "team_member_user_idx" ON "team_members" USING btree ("userId");
CREATE UNIQUE INDEX "team_member_unique_idx" ON "team_members" USING btree ("teamId", "userId");

--
-- Class TeamScore as table team_scores
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
-- Class TeamSetlistScore as table team_setlist_scores
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
-- Class TeamSetlist as table team_setlists
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
-- Class Team as table teams
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
-- Class UserAppData as table user_app_data
--
CREATE TABLE "user_app_data" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "applicationId" bigint NOT NULL,
    "preferences" text,
    "settings" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "user_app_data_user_app_idx" ON "user_app_data" USING btree ("userId", "applicationId");

--
-- Class UserLibrary as table user_libraries
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
-- Class UserStorage as table user_storage
--
CREATE TABLE "user_storage" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "usedBytes" bigint NOT NULL,
    "quotaBytes" bigint NOT NULL,
    "lastCalculatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "user_storage_user_idx" ON "user_storage" USING btree ("userId");

--
-- Class User as table users
--
CREATE TABLE "users" (
    "id" bigserial PRIMARY KEY,
    "username" text NOT NULL,
    "passwordHash" text NOT NULL,
    "displayName" text,
    "avatarPath" text,
    "bio" text,
    "preferredInstrument" text,
    "isAdmin" boolean NOT NULL,
    "isDisabled" boolean NOT NULL,
    "mustChangePassword" boolean NOT NULL,
    "lastLoginAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "user_username_idx" ON "users" USING btree ("username");

--
-- Class CloudStorageEntry as table serverpod_cloud_storage
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- Class FutureCallEntry as table serverpod_future_call
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- Class ServerHealthMetric as table serverpod_health_metric
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- Class LogEntry as table serverpod_log
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId");

--
-- Class MessageLogEntry as table serverpod_message_log
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

--
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- Class DatabaseMigrationVersion as table serverpod_migrations
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- Class QueryLogEntry as table serverpod_query_log
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId");

--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- Class SessionLogEntry as table serverpod_session_log
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "userId" text,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- Foreign relations for "annotations" table
--
ALTER TABLE ONLY "annotations"
    ADD CONSTRAINT "annotations_fk_0"
    FOREIGN KEY("instrumentScoreId")
    REFERENCES "instrument_scores"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "instrument_scores" table
--
ALTER TABLE ONLY "instrument_scores"
    ADD CONSTRAINT "instrument_scores_fk_0"
    FOREIGN KEY("scoreId")
    REFERENCES "scores"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "scores" table
--
ALTER TABLE ONLY "scores"
    ADD CONSTRAINT "scores_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "setlist_scores" table
--
ALTER TABLE ONLY "setlist_scores"
    ADD CONSTRAINT "setlist_scores_fk_0"
    FOREIGN KEY("setlistId")
    REFERENCES "setlists"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "setlist_scores"
    ADD CONSTRAINT "setlist_scores_fk_1"
    FOREIGN KEY("scoreId")
    REFERENCES "scores"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "setlists" table
--
ALTER TABLE ONLY "setlists"
    ADD CONSTRAINT "setlists_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "team_instrument_scores" table
--
ALTER TABLE ONLY "team_instrument_scores"
    ADD CONSTRAINT "team_instrument_scores_fk_0"
    FOREIGN KEY("teamScoreId")
    REFERENCES "team_scores"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "team_members" table
--
ALTER TABLE ONLY "team_members"
    ADD CONSTRAINT "team_members_fk_0"
    FOREIGN KEY("teamId")
    REFERENCES "teams"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "team_members"
    ADD CONSTRAINT "team_members_fk_1"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "team_scores" table
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
-- Foreign relations for "team_setlist_scores" table
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
-- Foreign relations for "team_setlists" table
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
-- Foreign relations for "teams" table
--
ALTER TABLE ONLY "teams"
    ADD CONSTRAINT "teams_fk_0"
    FOREIGN KEY("createdById")
    REFERENCES "users"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "user_app_data" table
--
ALTER TABLE ONLY "user_app_data"
    ADD CONSTRAINT "user_app_data_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "user_libraries" table
--
ALTER TABLE ONLY "user_libraries"
    ADD CONSTRAINT "user_libraries_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "user_storage" table
--
ALTER TABLE ONLY "user_storage"
    ADD CONSTRAINT "user_storage_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_log" table
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_message_log" table
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_query_log" table
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR musheet
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('musheet', '20260106032458406', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260106032458406', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
