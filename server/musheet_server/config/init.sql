-- MuSheet Database Initialization Script
-- This script is run when the PostgreSQL container is first created

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Grant permissions to musheet user
GRANT ALL PRIVILEGES ON DATABASE musheet TO musheet;

-- The actual table creation is handled by Serverpod migrations
-- This file is for any initial setup that needs to happen before the server starts

-- Create uploads directory tracking (optional, for advanced file management)
-- CREATE TABLE IF NOT EXISTS file_uploads (
--     id SERIAL PRIMARY KEY,
--     path VARCHAR(500) NOT NULL,
--     size_bytes BIGINT NOT NULL,
--     mime_type VARCHAR(100),
--     uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
--     user_id INT REFERENCES users(id)
-- );

-- Insert default application record for MuSheet
-- This will be done by the server on first run