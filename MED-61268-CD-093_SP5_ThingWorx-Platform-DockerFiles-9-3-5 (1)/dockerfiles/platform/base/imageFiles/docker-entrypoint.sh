#!/bin/bash
set -e
# export all variables to be sure they are visible to docker-helper
set -a

for default in $(cat /usr/local/etc/default-vars-base /usr/local/etc/default-vars); do
  var=$(echo -n "${default}" | grep -oP '(?<=DEFAULT_)[^=]+')
  default_val=$(echo -n "${default}" | cut -d = -f 2-)
  env_val=$(eval echo \$${var})
  if [ -z "${env_val}" ]; then
    if [ "${DOCKER_DEBUG}" == "true" ]; then
        echo "Setting ${var} to default value: ${default_val}"
    fi
    eval export ${var}="${default_val}"
  fi
done

# if we are running in cluster mode we require a platform id, check if hostname contains ordinal at end
# this change is only for kubernetes stateful pods and should be removed if we are able to pass in pod ordinal in future
if [ "${ENABLE_CLUSTERED_MODE}" == "true" ] && [ -z "${PLATFORM_ID}" ] &&  [[ `hostname` =~ -([0-9]+)$ ]]; then
    export PLATFORM_ID="p${BASH_REMATCH[1]}"
fi

export THINGWORX_PLATFORM_SETTINGS="/ThingworxPlatform"
export THINGWORX_STORAGE="/ThingworxStorage"
export THINGWORX_BACKUP_STORAGE="/ThingworxBackupStorage"
export IGNITE_WORK_DIR="/app/ignite/work"
export KEYSTORE_DIR="/app/opt/"
mkdir -p "${THINGWORX_PLATFORM_SETTINGS}" "${THINGWORX_STORAGE}" "${THINGWORX_BACKUP_STORAGE}" "${IGNITE_WORK_DIR}" "${KEYSTORE_DIR}"

# Template processer will copy the processed files to below directories (these files/folders will be removed later).
export TEMP_PLATFORM_SETTINGS_DIR="/app/tmp/THINGWORX_PLATFORM_SETTINGS"
export TEMP_CATALINA_DIR="/app/tmp/CATALINA_BASE"
mkdir -p "${TEMP_PLATFORM_SETTINGS_DIR}" "${TEMP_CATALINA_DIR}"

echo "Generating configuration files with template-processor"
/opt/template-processor/bin/template-processor run-commands

# merge platform settings and put in right location
(cd "${TEMP_PLATFORM_SETTINGS_DIR}"
echo "Merging reference conf with overrides"
jq -s '.[0] * .[1] * .[2] * .[3]' \
   /@var_dirs@/THINGWORX_PLATFORM_SETTINGS/platform-settings-reference.json \
   platform-settings-overrides.json \
   platform-settings-overrides-base.json \
   platform-settings-customer-overrides.json \
   > "${THINGWORX_PLATFORM_SETTINGS}"/platform-settings.json

if [ "${DOCKER_DEBUG}" == "true" ]; then
    echo "Rendered platform-settings.json:"
    cat "${THINGWORX_PLATFORM_SETTINGS}"/platform-settings.json
fi

# merge overrides and logback.xml if override is not empty, and put in final location
fsize=$(wc -c <"/app/tmp/logback.override.xml")
if [ $fsize -gt 1 ]; then
  echo "Merging logback configuration with overrides"
  /opt/xmlmerge/bin/xmlmerge "logback.xml" "/app/tmp/logback.override.xml" "${THINGWORX_PLATFORM_SETTINGS}/logback.xml"
else
  cp logback.xml "${THINGWORX_PLATFORM_SETTINGS}"
fi
)

# TW-94100 Prevent runtime changes to logging configuration file
chmod a-w "${THINGWORX_PLATFORM_SETTINGS}/logback.xml"

# copy over dev license if it exists and using trial license
LICENSE_FILE="/opt/trial.bin"
if [[ "${USE_TRIAL_LICENSE}" != "false" && -f "$LICENSE_FILE" ]]; then
  echo "Using the included trial license"
  cp "$LICENSE_FILE" "${THINGWORX_PLATFORM_SETTINGS}"/license.bin
fi

# move files in variablized directories to their final location
install-var-dirs.sh

cp -r $CATALINA_HOME/webapps/. $CATALINA_BASE/webapps/
cp -r -n $CATALINA_HOME/conf/. $CATALINA_BASE/conf/
cp -r /app/tmp/CATALINA_BASE/.  $CATALINA_BASE/conf/

# update web configuration if override provided
fsize=$(wc -c <"/app/tmp/web.override.xml")
if [ $fsize -gt 1 ]; then
  echo "Merging web configuration with overrides"
  /opt/xmlmerge/bin/xmlmerge "$CATALINA_HOME/webapps/Thingworx/WEB-INF/web.xml" "/app/tmp/web.override.xml" "$CATALINA_BASE/webapps/Thingworx/WEB-INF/web.xml"
fi

mkdir -p $CATALINA_BASE/temp
chown -R "${APP_USER}:${APP_USER}" $CATALINA_BASE
chmod -R 750 $CATALINA_BASE

# remove all temp files/folders, not needed after this
rm -rf "/app/tmp/"

# copy cacerts file if it is not already present, could be mounted
if [ ! -f "/ThingworxPlatform/java-truststore/cacerts" ]; then
  mkdir -p /ThingworxPlatform/java-truststore/
  cp -v "$(dirname $(dirname $(readlink -f $(which java))))/lib/security/cacerts" /ThingworxPlatform/java-truststore/
fi

# TW-96156 Ensure ownership only 1-level deep on ThingworxStorage and ThingworxBackupStorage,
# as they could contain many files accessed over network-attached storage
find "${THINGWORX_STORAGE}" -maxdepth 1 -print0 | xargs -0 -r chown "${APP_USER}:${APP_USER}"
find "${THINGWORX_BACKUP_STORAGE}" -maxdepth 1 -print0 | xargs -0 -r chown "${APP_USER}:${APP_USER}"
chown -R "${APP_USER}:${APP_USER}" "${THINGWORX_PLATFORM_SETTINGS}"
chown -R "${APP_USER}:${APP_USER}" "${IGNITE_WORK_DIR}"

# workaround for https://github.com/docker/docker/issues/9547
sync

exec gosu "${APP_USER}" "${CATALINA_HOME}/bin/catalina.sh" "${@}"
