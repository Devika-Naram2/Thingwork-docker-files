ARG TAG_VERSION
ARG BASE_IMAGE

FROM ${BASE_IMAGE} as builder

ARG PLATFORM_VERSION
ARG PLATFORM_ARCHIVE
ARG SQLDRIVER_VERSION
ARG SQLDRIVER_ARCHIVE

COPY staging/${PLATFORM_ARCHIVE} staging/${SQLDRIVER_ARCHIVE} /tmp/

RUN apt-get update && apt-get install -y --no-install-recommends unzip

RUN unzip "/tmp/${PLATFORM_ARCHIVE}" \
    && unzip -o -d Thingworx Thingworx.war \
    && tar -xvf /tmp/${SQLDRIVER_ARCHIVE} \
    && mv sqljdbc_7.4/enu/mssql-jdbc-7.4.1.jre11.jar /tmp/sqljdbc42-${SQLDRIVER_VERSION}.jar

FROM thingworx/tw-platform-base:${TAG_VERSION}

COPY --from=builder /Thingworx ${CATALINA_HOME}/webapps/Thingworx/.
COPY --from=builder /tmp/sqljdbc42-*.jar ${CATALINA_HOME}/lib/.
COPY imageFiles/ /

RUN chown -R "${APP_USER}:${APP_USER}" /@var_dirs@ \
    && chown -R "${APP_USER}:${APP_USER}" /usr

RUN if find / -ignore_readdir_race -nouser ! -path "/" ! -path "/kaniko*" ! -path "/workspace*" | grep -q .; \
    then echo "Unowned files or directories were found" && exit 1; fi && \
    if find / -ignore_readdir_race -nogroup ! -path "/" ! -path "/kaniko*" ! -path "/workspace*" | grep -q .; \
    then echo "Ungrouped files or directories were found" && exit 1; fi
