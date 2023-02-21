#!/bin/bash

function log {
  echo "[$(date +"%m-%d-%y %H:%M:%S")]$*"
}

PATH="/opt/mssql-tools/bin:${PATH}"

if [ -z "${DATABASE_ADMIN_USERNAME}" ]; then
  DATABASE_ADMIN_USERNAME="SA"
fi

until /opt/mssql-tools/bin/sqlcmd -S "${DATABASE_HOST},${DATABASE_PORT}" -U "${DATABASE_ADMIN_USERNAME}" -P "${DATABASE_ADMIN_PASSWORD}" -h -1 -Q "SET NOCOUNT ON; SELECT SERVERPROPERTY('ServerName')"; do
  log "[INFO] waiting for db to start...";
  sleep 10;
done

log "[INFO] AzureSQL is ready"
