ARG TAG_VERSION
ARG BASE_IMAGE

FROM ${BASE_IMAGE} as builder

ARG PLATFORM_VERSION
ARG PLATFORM_ARCHIVE

COPY staging/${PLATFORM_ARCHIVE} /tmp/
RUN apt-get update && apt-get install -y --no-install-recommends unzip \
    && unzip "/tmp/${PLATFORM_ARCHIVE}" \
    && unzip -o -d Thingworx Thingworx.war

FROM thingworx/tw-platform-base:${TAG_VERSION}

COPY --from=builder /Thingworx ${CATALINA_HOME}/webapps/Thingworx/.
COPY imageFiles/ /

RUN chown -R "${APP_USER}:${APP_USER}" /@var_dirs@ \
    && chown -R "${APP_USER}:${APP_USER}" /usr

RUN if find / -ignore_readdir_race -nouser ! -path "/" ! -path "/kaniko*" ! -path "/workspace*" | grep -q .; \
    then echo "Unowned files or directories were found" && exit 1; fi && \
    if find / -ignore_readdir_race -nogroup ! -path "/" ! -path "/kaniko*" ! -path "/workspace*" | grep -q .; \
    then echo "Ungrouped files or directories were found" && exit 1; fi