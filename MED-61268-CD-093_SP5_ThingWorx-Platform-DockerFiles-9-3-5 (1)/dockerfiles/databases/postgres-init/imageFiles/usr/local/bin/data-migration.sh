#!/bin/bash
function log {
  echo "[$(date +"%m-%d-%y %H:%M:%S")]$*"
}

if [ "${DEBUG_SCRIPT}" == "true" ]; then
  set -x
fi

# fail if any of the subscripts return error exit code
set -e

export TWX_DATABASE_LOGIN="${TWX_DATABASE_USERNAME}"

# if no database name is specified then default name to schema name since this is what we used before
if [ -z "$TWX_DATABASE_DBNAME" ]; then
  export TWX_DATABASE_DBNAME="${TWX_DATABASE_SCHEMA}"
  log "[WARN] No dbname specified setting to schema ${TWX_DATABASE_SCHEMA}"
fi

export TWX_MANAGED_INSTANCE_NAME=""
if [ "${IS_AZURE_POSTGRES}" == "true" ]; then
  export TWX_MANAGED_INSTANCE_NAME="${DATABASE_HOST}"
  export TWX_DATABASE_LOGIN="${TWX_DATABASE_USERNAME}@${DATABASE_HOST}"
fi

# create password file for database so we don't have to pass on all commands
# format hostname:port:database:username:password
export PGPASSFILE="/tmp/.pgpass"
log "[INFO] Creating pgpass file at ${PGPASSFILE}"
cat > "${PGPASSFILE}" <<EOF
*:*:${TWX_DATABASE_DBNAME}:${TWX_DATABASE_LOGIN}:${TWX_DATABASE_PASSWORD}
EOF
chmod 600 "${PGPASSFILE}"

# Change into database scrip folder for migration process
cd ${DBSCRIPT_DIR}

# Define the args (making sure each arg has a trailing space, so any concatenation works right).
common_args="-y "
common_args+="-h ${DATABASE_HOST} "
common_args+="-p ${DATABASE_PORT} "
common_args+="-d ${TWX_DATABASE_DBNAME} "
common_args+="-s ${TWX_DATABASE_SCHEMA} "
common_args+="-u ${TWX_DATABASE_USERNAME} "
if [ ! -z "${TWX_MANAGED_INSTANCE_NAME}" ] ; then
  common_args+="--managed_instance ${TWX_MANAGED_INSTANCE_NAME} "
fi

# any data migration?
if [ -n "${DATA_MIGRATE_DATA_TABLE}" ] || [ -n "${DATA_MIGRATE_STREAM}" ] || [ -n "${DATA_MIGRATE_VALUE_STREAM}" ]; then

  # FROM_TIMEZONE must be specified
  if [ -z "${FROM_TIMEZONE}" ]; then
    log "[ERROR] Timezone migration requires FROM_TIMEZONE to be specified"
    exit 1   # force exit, don't do any of the migration
  fi

  # if destination timezone is not specified then default to UTC
  if [ -z "${TO_TIMEZONE}" ]; then
    export TO_TIMEZONE="UTC"
  fi

  log "[INFO] Timezone conversion from ${FROM_TIMEZONE} to ${TO_TIMEZONE}"
  log "[INFO] Migrate Data Table: ${DATA_MIGRATE_DATA_TABLE}"
  log "[INFO] Migrate Stream: ${DATA_MIGRATE_STREAM}"
  log "[INFO] Migrate Value Stream: ${DATA_MIGRATE_VALUE_STREAM}"
  log "[INFO] Chunk Size: ${DATA_MIGRATE_CHUNK_SIZE}"

  migration_args="--from_timezone ${FROM_TIMEZONE} "
  migration_args+="--to_timezone ${TO_TIMEZONE} "
  migration_args+="--chunk_size ${DATA_MIGRATE_CHUNK_SIZE} "
  if [[ -n "${SYSTEM_VERSION}" ]]; then
    migration_args+="--system_version_override ${SYSTEM_VERSION} "
  fi

  if [ "${DATA_MIGRATE_DATA_TABLE}" == "true" ]; then
    log "[INFO] Migrating data tables..."
    ./update_bigint_timezone_data_postgres.sh --update_data_table ${common_args} ${migration_args}
    log "[INFO] Completed data table"
  fi

  if [ "${DATA_MIGRATE_STREAM}" == "true" ]; then
    log "[INFO] Migrating stream data..."
    ./update_bigint_timezone_data_postgres.sh --update_stream ${common_args} ${migration_args}
    log "[INFO] Completed stream"
  fi

  if [ "${DATA_MIGRATE_VALUE_STREAM}" == "true" ]; then
    log "[INFO] Migrating value stream data..."
    ./update_bigint_timezone_data_postgres.sh --update_value_stream ${common_args} ${migration_args}
    log "[INFO] Completed value stream"
  fi
fi

if [ "${DATA_MIGRATE_CLEANUP}" == "true" ]; then
  log "[INFO] Cleaning up migration data..."

  ./cleanup_update_postgres.sh ${common_args}

  cleanup_args=""
  if [ "${DATA_MIGRATE_CLEANUP_ALL}" == "true" ]; then
    log "[INFO] Also cleaning up bigint/timezone backup tables..."
    cleanup_args+="--delete_all_backup_data "  # Specifies that the values_stream_backup, stream_backup and and data_table_backup tables get deleted.
  fi

  ./cleanup_bigint_timezone_data_update_postgres.sh ${common_args} ${cleanup_args}
  log "[INFO] Cleanup complete"
fi

# change back to root directory
cd  /

rm "${PGPASSFILE}"
