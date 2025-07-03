#!/bin/bash

# Database backup script example
# Usage: ./scripts/backup.sh [database_name]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DB_NAME=${1:-"myapp"}
BACKUP_DIR="$HOME/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"

echo -e "${YELLOW}Starting database backup...${NC}"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Example MySQL backup (uncomment and modify as needed)
# mysqldump -u root -p "$DB_NAME" > "$BACKUP_FILE"

# Example PostgreSQL backup (uncomment and modify as needed)
# pg_dump "$DB_NAME" > "$BACKUP_FILE"

# For demo purposes, create a sample backup file
echo "-- Sample database backup for $DB_NAME" > "$BACKUP_FILE"
echo "-- Created on $(date)" >> "$BACKUP_FILE"
echo "-- This is a demo backup file" >> "$BACKUP_FILE"

echo -e "${GREEN}✓ Backup completed: $BACKUP_FILE${NC}"
echo -e "${GREEN}✓ Backup size: $(du -h "$BACKUP_FILE" | cut -f1)${NC}"

# Optional: compress the backup
gzip "$BACKUP_FILE"
echo -e "${GREEN}✓ Backup compressed: ${BACKUP_FILE}.gz${NC}"