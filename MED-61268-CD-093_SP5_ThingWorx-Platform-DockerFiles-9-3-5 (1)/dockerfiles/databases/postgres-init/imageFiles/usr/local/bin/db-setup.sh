#!/bin/bash
if [ "${DEBUG_SCRIPT}" == "true" ]; then
  set -x
fi

function log {
  echo "[$(date +"%m-%d-%y %H:%M:%S")]$*"
}

# current directory
working_dir="$(pwd)"
log "[INFO] Working directory: ${working_dir}"

export DATABASE_ADMIN_LOGIN="${DATABASE_ADMIN_USERNAME}"
export TWX_DATABASE_LOGIN="${TWX_DATABASE_USERNAME}"
export TWX_MANAGED_INSTANCE_NAME=""

# if no database name is specified then default name to schema name since this is what we used before
if [ -z "${DATABASE_ADMIN_DBNAME}" ]; then
  export DATABASE_ADMIN_DBNAME="${DATABASE_ADMIN_SCHEMA}"
  log "[WARN] No admin dbname specified setting to schema ${DATABASE_ADMIN_SCHEMA}"
fi

# if no database name is specified then default name to schema name since this is what we used before
if [ -z "$TWX_DATABASE_DBNAME" ]; then
  export TWX_DATABASE_DBNAME="${TWX_DATABASE_SCHEMA}"
  log "[WARN] No dbname specified setting to schema ${TWX_DATABASE_SCHEMA}"
fi

if [ "${IS_AZURE_POSTGRES}" == "true" ]; then
  log "[INFO] This is a managed instance"
  export DATABASE_ADMIN_LOGIN="${DATABASE_ADMIN_USERNAME}@${DATABASE_HOST}"
  export TWX_DATABASE_LOGIN="${TWX_DATABASE_USERNAME}@${DATABASE_HOST}"
  export TWX_MANAGED_INSTANCE_NAME="${DATABASE_HOST}"
  export IS_RDS="yes"
fi

log "[INFO] DatabaseLogin: ${DATABASE_ADMIN_LOGIN}"
log "[INFO] ThingworxLogin: ${TWX_DATABASE_LOGIN}"

# create password file for database so we don't have to pass on all commands
# format hostname:port:database:username:password
export PGPASSFILE="${working_dir}/tmp/.pgpass"
cat > "${PGPASSFILE}" <<EOF
*:*:${TWX_DATABASE_DBNAME}:${TWX_DATABASE_LOGIN}:${TWX_DATABASE_PASSWORD}
*:*:${DATABASE_ADMIN_DBNAME}:${DATABASE_ADMIN_LOGIN}:${DATABASE_ADMIN_PASSWORD}
EOF
chmod 600 "${PGPASSFILE}"

# Change into database script folder
cd ${DBSCRIPT_DIR}

log "[INFO] Checking for database user ${TWX_DATABASE_USERNAME}..."
twx_user_count=$(psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -d "${TWX_DATABASE_DBNAME}" \
                      -U "${TWX_DATABASE_LOGIN}" \
                      -v ON_ERROR_STOP=1 \
                      -tAc "SELECT count(*) FROM pg_roles WHERE rolname='${TWX_DATABASE_USERNAME}'")
if [ "${twx_user_count}" != 1 ]; then
  log "User ${TWX_DATABASE_USERNAME} does not exist. Creating..."
  psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -d "${DATABASE_ADMIN_DBNAME}" \
       -U "${DATABASE_ADMIN_LOGIN}" -v ON_ERROR_STOP=1 \
       -tAc "CREATE USER ${TWX_DATABASE_USERNAME} WITH PASSWORD '${TWX_DATABASE_PASSWORD}';"
else
  log "[INFO] User ${TWX_DATABASE_USERNAME} already exists."
fi

log "[INFO] Checking for database ${TWX_DATABASE_DBNAME}..."
if ! psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -d "${TWX_DATABASE_DBNAME}" -U "${TWX_DATABASE_LOGIN}" -c ""; then
  log "[INFO] Database ${TWX_DATABASE_DBNAME} does not exist. Creating..."
  log "[INFO] IS RDS Instance: ${IS_RDS}"
  set -e
  if [ "${IS_RDS}" != "yes" ]; then
    psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -d "${DATABASE_ADMIN_DBNAME}" \
         -U "${DATABASE_ADMIN_LOGIN}" \
         -v database="${TWX_DATABASE_DBNAME}" -v username="${TWX_DATABASE_USERNAME}" \
         -v ON_ERROR_STOP=1 \
         -f "${DBSCRIPT_DIR}/thingworx-database-setup.sql"
  else
    psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -d "${DATABASE_ADMIN_DBNAME}" \
         -U "${DATABASE_ADMIN_LOGIN}" \
         -v database="${TWX_DATABASE_DBNAME}" -v username="${TWX_DATABASE_USERNAME}" \
         -v adminusername="${DATABASE_ADMIN_USERNAME}" -v ON_ERROR_STOP=1 \
         -f "${DBSCRIPT_DIR}/thingworx-rds-database-setup.sql"
  fi

  log "[INFO] Creating Schema..."
  psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -d "${TWX_DATABASE_DBNAME}" \
       -U "${TWX_DATABASE_LOGIN}" \
       -v user_name="${TWX_DATABASE_USERNAME}" -v schemaName="${TWX_DATABASE_SCHEMA}" \
       -v ON_ERROR_STOP=1 \
       -f "${DBSCRIPT_DIR}/thingworx-create-schema.sql"

  log "[INFO] Installing model schema..."
  psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -d "${TWX_DATABASE_DBNAME}" \
       -U "${TWX_DATABASE_LOGIN}" \
       -v user_name="${TWX_DATABASE_USERNAME}" \
       -v ON_ERROR_STOP=1 \
       -f "${DBSCRIPT_DIR}/thingworx-model-schema.sql"

  log "[INFO] Installing data schema..."
  psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -d "${TWX_DATABASE_DBNAME}" \
       -U "${TWX_DATABASE_LOGIN}" \
       -v user_name="${TWX_DATABASE_USERNAME}" \
       -v ON_ERROR_STOP=1 \
       -f "${DBSCRIPT_DIR}/thingworx-data-schema.sql"

  log "[INFO] Installing system schema..."
  psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -d "${TWX_DATABASE_DBNAME}" \
       -U "${TWX_DATABASE_LOGIN}" \
       -v user_name="${TWX_DATABASE_USERNAME}" \
       -v ON_ERROR_STOP=1 \
       -f "${DBSCRIPT_DIR}/thingworx-system-schema.sql"

  log "[INFO] Installing property schema..."
  psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -d "${TWX_DATABASE_DBNAME}" \
       -U "${TWX_DATABASE_LOGIN}" \
       -v user_name="${TWX_DATABASE_USERNAME}" \
       -v ON_ERROR_STOP=1 \
       -f "${DBSCRIPT_DIR}/thingworx-property-schema.sql"

  log "[INFO] Installing grants schema..."
  psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -d "${TWX_DATABASE_DBNAME}" \
       -U "${TWX_DATABASE_LOGIN}" \
       -v user_name="${TWX_DATABASE_USERNAME}" \
       -v ON_ERROR_STOP=1 \
       -f "${DBSCRIPT_DIR}/thingworx-grants-schema.sql"

else # check for migration

  # determine version if not specified
  if [[ -z "$SYSTEM_VERSION" ]]; then
    current_major=$(psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -d "${TWX_DATABASE_DBNAME}" \
                        -U "${TWX_DATABASE_LOGIN}" -v ON_ERROR_STOP=1 \
                        -tAc "SELECT major_version FROM system_version order by pid desc limit 1")
    current_minor=$(psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -d "${TWX_DATABASE_DBNAME}" \
                        -U "${TWX_DATABASE_LOGIN}" -v ON_ERROR_STOP=1 \
                        -tAc "SELECT minor_version FROM system_version order by pid desc limit 1")

    version="$current_major.$current_minor"
    log "[INFO] Database schema detected, current schema version is ${version}"
  else
    # pull from environment variable
    read -raversionarray<<< "${SYSTEM_VERSION}"
    version="${versionarray[0]}.${versionarray[1]}"
    log "[INFO] Database schema version specified as ${version}"
  fi

  # determine what to do next based on version
  if [[ "$version" == "." ]] || [[ -z "$version" ]]; then
    log "[ERROR] Unable to determine the system version"
    exit 1 # force exit, what we do next may be wrong
  elif [ "${version}" == "0.0" ]; then
    log "[WARN] This is a non-release build, migration will be skipped"
  else
    # fail if any of the subscripts return error exit code
    set -e

    # if we need to migrate timezone then FROM_TIMEZONE must be specified
    if [ "${version}" == "8.5" ] || [ "${FORCE_BIGINT_TIMEZONE_UPDATE}" == "true" ]; then
      log "[INFO] BIGINT and Timezone migration are required"
      if [ -z "${FROM_TIMEZONE}" ]; then
        log "[ERROR] Timezone migration requires FROM_TIMEZONE to be specified"
        exit 1   # force exit, don't do any of the migration
      fi
    fi

    # build the script args
    command_args=""
    if [[ -z "${UPGRADE_MODE}" ]]; then
      command_args+="--update_all "
    else
      command_args+="${UPGRADE_MODE} "
    fi
    command_args+="-y "
    command_args+="-h ${DATABASE_HOST} "
    command_args+="-p ${DATABASE_PORT} "
    command_args+="-d ${TWX_DATABASE_DBNAME} "
    command_args+="-s ${TWX_DATABASE_SCHEMA} "
    command_args+="-u ${TWX_DATABASE_USERNAME} "
    if [[ -n "${TWX_MANAGED_INSTANCE_NAME}" ]]; then
      command_args+="--managed_instance ${TWX_MANAGED_INSTANCE_NAME} "
    fi
    if [[ -n "$SYSTEM_VERSION" ]]; then
      command_args+="--system_version_override ${SYSTEM_VERSION} "
    fi

    # run base migration
    # NOTE: the script requires the raw username, not the login with managed host.   It builds itself
    log "[INFO] Running scripts for migration"
    log "[INFO] update_postgres.sh ${command_args}"
    ./update_postgres.sh ${command_args}

    # if we are coming from 8.5 database we need to update bigint and timezone
    if [ "${version}" == "8.5" ] || [ "${FORCE_BIGINT_TIMEZONE_UPDATE}" == "true" ]; then

      # if destination timezone is not specified then default to UTC
      if [ -z "${TO_TIMEZONE}" ]; then
        export TO_TIMEZONE="UTC"
      fi

      # NOTE: the scripts requires the raw username, not the login with managed host.   It builds itself
      log "[INFO] Migrating BIGINT and timezone from ${FROM_TIMEZONE} to ${TO_TIMEZONE} for data tables"
      log "[INFO] ./update_bigint_timezone_schema_postgres.sh ${command_args} --from_timezone ${FROM_TIMEZONE} --to_timezone ${TO_TIMEZONE}"
      ./update_bigint_timezone_schema_postgres.sh ${command_args} --from_timezone "${FROM_TIMEZONE}" --to_timezone "${TO_TIMEZONE}"
    fi
  fi

fi

# change back to root directory
cd ${working_dir}

if psql -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -d "${TWX_DATABASE_DBNAME}" -U "${TWX_DATABASE_LOGIN}" -c ""; then
    log "[INFO] success" > ${working_dir}/tmp/status.txt
fi

# remove password file
rm "${PGPASSFILE}"
