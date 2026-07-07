#!/bin/bash
# ==========================================
# PostgreSQL Restore Script
#
# Restores a backup into a FRESH database (not the live "bookingdb"),
# so restore can be verified without touching current data.
#
# Usage:
#   ./scripts/restore.sh database/backups/bookingdb_20260707_101500.sql
#   ./scripts/restore.sh database/backups/bookingdb_20260707_101500.sql my_custom_target_db
# ==========================================
set -e

CONTAINER_NAME="bookingapp-postgres"
DB_USER="postgres"

if [ $# -eq 0 ]; then
    echo "Usage:"
    echo "  ./scripts/restore.sh <backup-file> [target-db-name]"
    exit 1
fi

BACKUP_FILE="$1"
TARGET_DB="${2:-bookingdb_restore_verify}"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Restoring '$BACKUP_FILE' into fresh database '$TARGET_DB'..."

# Drop the target database if a previous verification run left it behind,
# then create it clean.
docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres \
    -c "DROP DATABASE IF EXISTS ${TARGET_DB};"

docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d postgres \
    -c "CREATE DATABASE ${TARGET_DB};"

docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$TARGET_DB" < "$BACKUP_FILE"

echo "--------------------------------------"
echo "Restore completed. Verifying row counts in '$TARGET_DB'..."
echo "--------------------------------------"

docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$TARGET_DB" -c \
    "SELECT 'hotel_bookings' AS table_name, COUNT(*) AS row_count FROM hotel_bookings
     UNION ALL
     SELECT 'booking_events', COUNT(*) FROM booking_events;"

echo "--------------------------------------"
echo "If both row counts are non-zero and roughly match the source database,"
echo "the restore succeeded. See README.md 'Backup & Restore' section for"
echo "the full verification steps."
echo "--------------------------------------"
