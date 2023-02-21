#!/bin/bash

function log {
  echo "[$(date +"%m-%d-%y %H:%M:%S")] $*"
}

if [ "${DEBUG_SCRIPT}" == "true" ]; then
  set -x
fi

# determine login name format
export DATABASE_ADMIN_LOGIN="${DATABASE_ADMIN_USERNAME}"
if [ "${IS_AZURE_POSTGRES}" == "true" ]; then
  export DATABASE_ADMIN_LOGIN="${DATABASE_ADMIN_USERNAME}@${DATABASE_HOST}"
fi

# if no database name is specified then default name to schema name since this is what we used before
if [ -z "${DATABASE_ADMIN_DBNAME}" ]; then
  export DATABASE_ADMIN_DBNAME="${DATABASE_ADMIN_SCHEMA}"
  log "[WARN] No admin dbname specified setting to schema ${DATABASE_ADMIN_SCHEMA}"
fi

# create password file for database so we don't have to pass on all commands
# format hostname:port:database:username:password
export PGPASSFILE="/tmp/.pgpass"
cat > "${PGPASSFILE}" <<EOF
*:*:${DATABASE_ADMIN_DBNAME}:${DATABASE_ADMIN_LOGIN}:${DATABASE_ADMIN_PASSWORD}
EOF
chmod 600 "${PGPASSFILE}"

log "[INFO] Admin Connection:"
log "[INFO]  Host: ${DATABASE_HOST}"
log "[INFO]  Port: ${DATABASE_PORT}"
log "[INFO]  DBName: ${DATABASE_ADMIN_DBNAME}"
log "[INFO]  login: ${DATABASE_ADMIN_LOGIN}"

log "[INFO] Checking Postgres is available"
until psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -U "${DATABASE_ADMIN_LOGIN}" -d "${DATABASE_ADMIN_DBNAME}" -c '\q'; do
  >&2 log "[INFO] Postgres is unavailable - Waiting..."
  sleep 10
done
log "[INFO] Postgres is ready"

rm "${PGPASSFILE}"
