ARG BASE_IMAGE

FROM ${BASE_IMAGE} as builder

ARG PLATFORM_VERSION
ARG PLATFORM_ARCHIVE

COPY staging/${PLATFORM_ARCHIVE} /tmp/

RUN apt-get update && apt-get install -y --no-install-recommends unzip \
    && unzip -j "/tmp/${PLATFORM_ARCHIVE}" "install/*" -d "/tmp/install" \
    && unzip -j "/tmp/${PLATFORM_ARCHIVE}" "update/*" -d "/tmp/install" \
    && echo "${PLATFORM_VERSION}" > /tmp/install/platform.version

FROM ${BASE_IMAGE}

COPY imageFiles/ /
COPY --from=builder /tmp/install /tmp/install/.
COPY --from=builder /tmp/install /tmp/tw-db-scripts/.

RUN chmod -R 755 "/tmp/tw-db-scripts"

ENV DBSCRIPT_DIR="/tmp/tw-db-scripts"
ENV APP_USER=twadmin

RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
    adduser --uid 1337 --disabled-password --gecos "" --home "/home/${APP_USER}" "${APP_USER}" && \
    chmod 750 "/home/${APP_USER}"

RUN echo "Assigning execute permission to database setup scripts" && \
    chmod +x /usr/local/bin/db-setup.sh && \
    chmod +x /usr/local/bin/db-check.sh && \
    chmod +x /usr/local/bin/data-migration.sh && \
    chmod +x ${DBSCRIPT_DIR}/thingworxAzureManagedInstanceDBSetup.sh && \
    chmod +x ${DBSCRIPT_DIR}/thingworxAzureManagedInstanceSchemaSetup.sh && \
    chown -R ${APP_USER}: /tmp && \
    chmod -R u+w /tmp && \
    chown -R ${APP_USER}:${APP_USER} /usr

RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-transport-https ca-certificates gnupg locales curl jq \
    && locale-gen en_US.utf8 && update-locale

RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/msprod.list \
    && apt-get update && yes | apt-get install -y --no-install-recommends mssql-tools \
    && apt-get remove -y ca-certificates gnupg \
    && apt-get clean

# setting secure permissions on all existing log files - see CIS Security Benchmark ID 4.2.3
RUN find /var/log -type f -exec chmod g-wx,o-rwx "{}" + -o -type d -exec chmod g-w,o-rwx "{}" +

# dpkg stores installed package info at this location, odbc related files doesn't have proper ownership
# update the ownership to root as all other files at this location owned by root.
RUN chown -R root:root /var/lib/dpkg/info

# Ensure no unowned/ungrouped files or directories
RUN if find / -ignore_readdir_race -nouser ! -path "/" ! -path "/kaniko*" ! -path "/workspace*" | grep -q .; \
    then echo "Unowned files or directories were found" && exit 1; fi && \
    if find / -ignore_readdir_race -nogroup ! -path "/" ! -path "/kaniko*" ! -path "/workspace*" | grep -q .; \
    then echo "Ungrouped files or directories were found" && exit 1; fi

USER ${APP_USER}
ENTRYPOINT ["/usr/local/bin/db-setup.sh"]
