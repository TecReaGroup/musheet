#!/bin/bash

# MuSheet Database Backup Script
# Runs periodic backups of the PostgreSQL database

set -e

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/musheet_backup_$DATE.sql.gz"
RETENTION_DAYS=7

echo "=== MuSheet Database Backup ==="
echo "Date: $(date)"
echo "Backup file: $BACKUP_FILE"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Perform backup
echo "Creating backup..."
PGPASSWORD=$POSTGRES_PASSWORD pg_dump \
    -h $POSTGRES_HOST \
    -U $POSTGRES_USER \
    -d $POSTGRES_DB \
    --format=plain \
    --no-owner \
    --no-acl \
    | gzip > $BACKUP_FILE

# Verify backup
if [ -f "$BACKUP_FILE" ]; then
    SIZE=$(ls -lh $BACKUP_FILE | awk '{print $5}')
    echo "Backup created successfully: $SIZE"
else
    echo "ERROR: Backup failed!"
    exit 1
fi

# Clean up old backups
echo "Cleaning up old backups (older than $RETENTION_DAYS days)..."
find $BACKUP_DIR -name "musheet_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete

# List current backups
echo ""
echo "Current backups:"
ls -lh $BACKUP_DIR/musheet_backup_*.sql.gz 2>/dev/null || echo "No backups found"

echo ""
echo "Backup complete!"