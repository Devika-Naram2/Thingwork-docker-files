ARG TAG_VERSION
ARG BASE_IMAGE
ARG BASE_JAVA_IMAGE

FROM ${BASE_IMAGE} as builder

ARG TOMCAT_VERSION
ARG TOMCAT_ARCHIVE
ARG LICENSE_FILE
ARG PLATFORM_SETTINGS_FILE
ARG TEMPLATE_PROCESSOR_ARCHIVE
ARG XMLMERGE_ARCHIVE

COPY staging/ /tmp/
RUN cd /opt \
    && tar -xvf "/tmp/${TOMCAT_ARCHIVE}" \
    && mv "apache-tomcat-${TOMCAT_VERSION}" apache-tomcat \
    && echo "${TOMCAT_VERSION}" > apache-tomcat/tomcat.version \
    && rm -rvf apache-tomcat/webapps/*

RUN mkdir -p /opt/template-processor \
    && tar -xvzf "/tmp/${TEMPLATE_PROCESSOR_ARCHIVE}" -C "/opt/template-processor" --strip-components=1

RUN mkdir -p /opt/xmlmerge \
    && tar -xvzf "/tmp/${XMLMERGE_ARCHIVE}" -C "/opt/xmlmerge" --strip-components=1

RUN mkdir -p "/@var_dirs@/THINGWORX_PLATFORM_SETTINGS" \
    && if [ -f "/tmp/${LICENSE_FILE}" ]; then mv "/tmp/${LICENSE_FILE}" "/opt/trial.bin"; fi \
    && mv "/tmp/${PLATFORM_SETTINGS_FILE}" "/@var_dirs@/THINGWORX_PLATFORM_SETTINGS/platform-settings-reference.json"

FROM thingworx/base:${TAG_VERSION}

ENV CATALINA_HOME=/opt/apache-tomcat
ENV CATALINA_BASE=/app${CATALINA_HOME}
ENV PATH=$CATALINA_BASE/bin:$CATALINA_HOME/bin:${PATH}
ENV ENABLE_SNI=true
ENV ENABLE_CONSOLE_OUTPUT=false

COPY --from=builder /opt/ /opt/.
COPY --from=builder /@var_dirs@/THINGWORX_PLATFORM_SETTINGS/ /@var_dirs@/THINGWORX_PLATFORM_SETTINGS/.

COPY imageFiles/ /

RUN apt-get update \
    # curl is here so that docker-compose can run a health check
    && apt-get install -y --no-install-recommends curl jq \
    && apt-get clean \
    && mkdir "${CATALINA_HOME}/keystore" \
    && mkdir -p "${CATALINA_BASE}" \
    && chown -R "${APP_USER}:${APP_USER}" "${CATALINA_HOME}" \
    && chown -R "${APP_USER}:${APP_USER}" "${CATALINA_BASE}" \
    && chmod g-w,o-rwx "${CATALINA_HOME}" \
    && chmod u-x,g-w,o-rwx "${CATALINA_HOME}/conf" \
    && chmod +x /docker-entrypoint.sh \
    && chown -R "${APP_USER}:${APP_USER}" /docker-entrypoint.sh \
    && chown -R "${APP_USER}:${APP_USER}" /opt \
    && chown -R "${APP_USER}:${APP_USER}" /usr \
    && chown -R "${APP_USER}:${APP_USER}" /@var_dirs@

RUN if find / -ignore_readdir_race -nouser ! -path "/" ! -path "/kaniko*" ! -path "/workspace*" | grep -q .; \
    then echo "Unowned files or directories were found" && exit 1; fi && \
    if find / -ignore_readdir_race -nogroup ! -path "/" ! -path "/kaniko*" ! -path "/workspace*" | grep -q .; \
    then echo "Ungrouped files or directories were found" && exit 1; fi

VOLUME /ThingworxStorage
VOLUME /ThingworxBackupStorage
VOLUME /ThingworxPlatform

EXPOSE 8080

# setting secure permissions on all existing log files - see CIS Security Benchmark ID 4.2.3
RUN find /var/log -type f -exec chmod g-wx,o-rwx "{}" + -o -type d -exec chmod g-w,o-rwx "{}" +

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["run"]
