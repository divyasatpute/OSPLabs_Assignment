#!/bin/bash
# ==========================================
# PostgreSQL Backup Script
# Creates a timestamped dump of the local bookingdb database.
# ==========================================
set -e

CONTAINER_NAME="bookingapp-postgres"
DB_NAME="bookingdb"
DB_USER="postgres"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/../database/backups"

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"

echo "Starting PostgreSQL backup..."
echo "Container: $CONTAINER_NAME"
echo "Database:  $DB_NAME"

docker exec "$CONTAINER_NAME" pg_dump \
    -U "$DB_USER" \
    --clean \
    --if-exists \
    "$DB_NAME" > "$BACKUP_FILE"

echo "Backup completed successfully."
echo "Backup saved to: $BACKUP_FILE"
