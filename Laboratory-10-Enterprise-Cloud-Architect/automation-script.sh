#!/usr/bin/env bash
set -Eeuo pipefail

# Run from the project directory. Creates timestamped database and uploads backups.
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${BACKUP_DIR:-${PROJECT_DIR}/backups}"
STAMP="$(date +'%Y%m%d-%H%M%S')"

if [[ ! -f "${PROJECT_DIR}/.env" ]]; then
  echo "ERROR: ${PROJECT_DIR}/.env not found. Copy .env.example to .env and configure it." >&2
  exit 1
fi

# Load environment variables without printing secrets.
set -a
# shellcheck disable=SC1091
source "${PROJECT_DIR}/.env"
set +a

mkdir -p "${BACKUP_DIR}"
chmod 700 "${BACKUP_DIR}"

echo "Creating MySQL backup..."
docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T db \
  sh -c 'exec mysqldump --single-transaction -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' \
  | gzip > "${BACKUP_DIR}/mysql-${STAMP}.sql.gz"

echo "Creating WordPress files backup..."
docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T wordpress \
  tar -czf - -C /var/www/html wp-content/uploads \
  > "${BACKUP_DIR}/wordpress-uploads-${STAMP}.tar.gz"

# Keep the 14 newest backup files of each type; delete older ones.
find "${BACKUP_DIR}" -maxdepth 1 -type f -name 'mysql-*.sql.gz' -printf '%T@ %p\n' \
  | sort -nr | awk 'NR>14 { $1=""; sub(/^ /,""); print }' | xargs -r rm -f --
find "${BACKUP_DIR}" -maxdepth 1 -type f -name 'wordpress-uploads-*.tar.gz' -printf '%T@ %p\n' \
  | sort -nr | awk 'NR>14 { $1=""; sub(/^ /,""); print }' | xargs -r rm -f --

echo "Backup complete: ${BACKUP_DIR}"
