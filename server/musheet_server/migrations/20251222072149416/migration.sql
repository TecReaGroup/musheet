BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "instrument_scores" DROP COLUMN "pdfPath";

--
-- MIGRATION VERSION FOR musheet
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('musheet', '20251222072149416', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251222072149416', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();


COMMIT;
