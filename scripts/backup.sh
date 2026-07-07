#!/usr/bin/env bash
# backup.sh — create a timestamped dump of the local PostgreSQL database.
#
# Dumps from the running docker-compose "postgres" service using pg_dump in
# the container, so you do not need a local psql/pg_dump install.
#
# Usage:
#   ./scripts/backup.sh
#
# Output:
#   backups/<db>_YYYYmmdd_HHMMSS.dump   (custom format, compressed)
#
# Override defaults via env vars:
#   DB_NAME, DB_USER, COMPOSE_SERVICE, BACKUP_DIR, COMPOSE_FILE
set -euo pipefail

# Resolve repo root regardless of where the script is called from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

DB_NAME="${DB_NAME:-appdb}"
DB_USER="${DB_USER:-appuser}"
COMPOSE_SERVICE="${COMPOSE_SERVICE:-postgres}"
COMPOSE_FILE="${COMPOSE_FILE:-${ROOT_DIR}/db/docker-compose.yml}"
BACKUP_DIR="${BACKUP_DIR:-${ROOT_DIR}/backups}"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTFILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.dump"

mkdir -p "${BACKUP_DIR}"

echo ">> Backing up database '${DB_NAME}' from service '${COMPOSE_SERVICE}'..."

# -Fc  = custom format (compressed, restorable with pg_restore)
docker compose -f "${COMPOSE_FILE}" exec -T "${COMPOSE_SERVICE}" \
    pg_dump -U "${DB_USER}" -d "${DB_NAME}" -Fc > "${OUTFILE}"

SIZE="$(du -h "${OUTFILE}" | cut -f1)"
echo ">> Backup complete: ${OUTFILE} (${SIZE})"
