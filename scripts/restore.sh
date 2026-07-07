#!/usr/bin/env bash
# restore.sh — restore a dump into a fresh local database.
#
# Drops and recreates the target database inside the running docker-compose
# "postgres" service, then restores the given (or latest) backup into it.
#
# Usage:
#   ./scripts/restore.sh                          # restore the newest backup
#   ./scripts/restore.sh backups/appdb_XXXX.dump  # restore a specific file
#
# Override defaults via env vars:
#   DB_NAME, DB_USER, COMPOSE_SERVICE, BACKUP_DIR, COMPOSE_FILE
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

DB_NAME="${DB_NAME:-appdb}"
DB_USER="${DB_USER:-appuser}"
COMPOSE_SERVICE="${COMPOSE_SERVICE:-postgres}"
COMPOSE_FILE="${COMPOSE_FILE:-${ROOT_DIR}/db/docker-compose.yml}"
BACKUP_DIR="${BACKUP_DIR:-${ROOT_DIR}/backups}"

# Pick the backup file: argument, or the most recent *.dump in BACKUP_DIR.
BACKUP_FILE="${1:-}"
if [[ -z "${BACKUP_FILE}" ]]; then
    BACKUP_FILE="$(ls -1t "${BACKUP_DIR}"/*.dump 2>/dev/null | head -n1 || true)"
fi

if [[ -z "${BACKUP_FILE}" || ! -f "${BACKUP_FILE}" ]]; then
    echo "!! No backup file found. Pass one explicitly or run ./scripts/backup.sh first." >&2
    exit 1
fi

echo ">> Restoring '${BACKUP_FILE}' into a fresh database '${DB_NAME}'..."

# Recreate the target DB. We connect to the maintenance 'postgres' database
# to drop/create, terminating any existing connections first.
docker compose -f "${COMPOSE_FILE}" exec -T "${COMPOSE_SERVICE}" \
    psql -U "${DB_USER}" -d postgres -v ON_ERROR_STOP=1 <<SQL
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '${DB_NAME}' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS ${DB_NAME};
CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
SQL

# Restore the dump into the freshly created database.
docker compose -f "${COMPOSE_FILE}" exec -T "${COMPOSE_SERVICE}" \
    pg_restore -U "${DB_USER}" -d "${DB_NAME}" --no-owner --exit-on-error \
    < "${BACKUP_FILE}"

echo ">> Restore complete. Row counts:"
docker compose -f "${COMPOSE_FILE}" exec -T "${COMPOSE_SERVICE}" \
    psql -U "${DB_USER}" -d "${DB_NAME}" -c \
    "SELECT 'hotel_bookings' AS table, count(*) FROM hotel_bookings
     UNION ALL
     SELECT 'booking_events', count(*) FROM booking_events;"
