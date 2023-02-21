#!/bin/bash

function log {
  echo "[$(date +"%m-%d-%y %H:%M:%S")]$*"
}

# fail if any of the subscripts return error exit code
set -e

PATH="/opt/mssql-tools/bin:${PATH}"

log "[INFO] Checking for database user ${TWX_DATABASE_USERNAME}..."
if sqlcmd -S "${DATABASE_HOST},${DATABASE_PORT}" -U "${DATABASE_ADMIN_USERNAME}" -P "${DATABASE_ADMIN_PASSWORD}" -h -1 -Q "SET NOCOUNT ON; SELECT name FROM sys.database_principals WHERE name = '${TWX_DATABASE_USERNAME}'" | grep -w "${TWX_DATABASE_USERNAME}"; then
    log "[INFO] User ${TWX_DATABASE_USERNAME} already exists."
else
    log "[INFO] User ${TWX_DATABASE_USERNAME} does not exist. Creating..."
    sqlcmd -S "${DATABASE_HOST},${DATABASE_PORT}" -U "${DATABASE_ADMIN_USERNAME}" -P "${DATABASE_ADMIN_PASSWORD}" -Q "CREATE LOGIN ${TWX_DATABASE_USERNAME} WITH PASSWORD = '${TWX_DATABASE_PASSWORD}'"
fi

# current directory
working_dir="$(pwd)"
log "[INFO] Working directory: ${working_dir}"

cd "${DBSCRIPT_DIR}"

# Check to see if the given database schema already exists. This determines whether to create the database or migrate it.
log "[INFO] Checking for database schema ${TWX_DATABASE_SCHEMA}..."
dbCount=0
dbCount=$(sqlcmd -S ${DATABASE_HOST},${DATABASE_PORT} -U "${DATABASE_ADMIN_USERNAME}" -P "${DATABASE_ADMIN_PASSWORD}" -W -h -1 -Q "SET NOCOUNT on; SELECT COUNT(*) FROM sys.databases WHERE name = '${TWX_DATABASE_SCHEMA}'; SET NOCOUNT off;")
if [ $dbCount -ge 1 ]; then
    if [[ -z "$SYSTEM_VERSION" ]]; then
      current_major=$(sqlcmd -S ${DATABASE_HOST},${DATABASE_PORT} -d "${TWX_DATABASE_SCHEMA}" -U ${TWX_DATABASE_USERNAME} -P ${TWX_DATABASE_PASSWORD} -W -h -1 -Q 'SET NOCOUNT on; SELECT major_version FROM system_version ORDER BY pid OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY; SET NOCOUNT off;')
      current_minor=$(sqlcmd -S ${DATABASE_HOST},${DATABASE_PORT} -d "${TWX_DATABASE_SCHEMA}" -U ${TWX_DATABASE_USERNAME} -P ${TWX_DATABASE_PASSWORD} -W -h -1 -Q 'SET NOCOUNT on; SELECT minor_version FROM system_version ORDER BY pid OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY; SET NOCOUNT off;')

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
      # if we need to migrate timezone then FROM_TIMEZONE must be specified
      if [ "${version}" == "8.5" ] || [ "${FORCE_BIGINT_TIMEZONE_UPDATE}" == "true" ]; then
        log "[INFO] BIGINT and Timezone migration are required"
        if [ -z "${FROM_TIMEZONE}" ]; then
          log "[ERROR] Timezone migration requires FROM_TIMEZONE to be specified"
          exit 1   # force exit, don't do any of the migration
        fi
      fi

      export SQLCMDPASSWORD="${TWX_DATABASE_PASSWORD}"

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
      command_args+="-d ${TWX_DATABASE_SCHEMA} "
      command_args+="-u ${TWX_DATABASE_USERNAME} "
      if [[ -n "$SYSTEM_VERSION" ]]; then
        command_args+="--system_version_override ${SYSTEM_VERSION} "
      fi

      # run base migration
      # NOTE: the script requires the raw username, not the login with managed host.   It builds itself
      log "[INFO] Running scripts for migration"
      log "[INFO] update_mssql.sh ${command_args}"
      ./update_mssql.sh ${command_args}

      # if we are coming from 8.5 database we need to update bigint and timezone
      if [ "${version}" == "8.5" ] || [ "${FORCE_BIGINT_TIMEZONE_UPDATE}" == "true" ]; then

        # if destination timezone is not specified then default to UTC
        if [ -z "${TO_TIMEZONE}" ]; then
          export TO_TIMEZONE="UTC"
        fi

        # NOTE: the scripts requires the raw username, not the login with managed host.   It builds itself
        log "[INFO] Migrating BIGINT and timezone from ${FROM_TIMEZONE} to ${TO_TIMEZONE} for data tables"
        log "[INFO] ./update_bigint_timezone_schema_mssql.sh ${command_args} --from_timezone ${FROM_TIMEZONE} --to_timezone ${TO_TIMEZONE}"
        ./update_bigint_timezone_schema_mssql.sh ${command_args} --from_timezone "${FROM_TIMEZONE}" --to_timezone "${TO_TIMEZONE}"
      fi
    fi
else
    log "[INFO] Database ${TWX_DATABASE_SCHEMA} does not exist. Creating..."
    ./thingworxAzureManagedInstanceDBSetup.sh -h "${DATABASE_HOST}" \
                                                         -a "${DATABASE_ADMIN_USERNAME}" -r "${DATABASE_ADMIN_PASSWORD}" \
                                                         -l "${TWX_DATABASE_USERNAME}" -u "${TWX_DATABASE_USERNAME}" \
                                                         -d "${TWX_DATABASE_SCHEMA}" -s "${TWX_DATABASE_SCHEMA}"
    ./thingworxAzureManagedInstanceSchemaSetup.sh -h "${DATABASE_HOST}" \
                                                                 -l "${TWX_DATABASE_USERNAME}" -r "${TWX_DATABASE_PASSWORD}" \
                                                                 -d "${TWX_DATABASE_SCHEMA}" -o all
fi

unset SQLCMDPASSWORD

# change back to root directory
cd ${working_dir}

log "[INFO] success" > /tmp/status.txt
