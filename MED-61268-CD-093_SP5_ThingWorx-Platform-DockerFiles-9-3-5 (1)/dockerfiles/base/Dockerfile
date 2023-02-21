ARG BASE_IMAGE

FROM ${BASE_IMAGE} as builder

ARG JAVA_ARCHIVE
ARG JAVA_PRODUCT_VERSION

COPY staging/${JAVA_ARCHIVE} /tmp/

RUN mkdir -p /opt/jdk && \
    tar -C /opt/jdk --strip-components=1 -xavf "/tmp/${JAVA_ARCHIVE}"

FROM ${BASE_IMAGE}

ARG GOSU_VERSION=1.10
ENV APP_USER=twadmin

ENV JAVA_HOME=/opt/jdk \
    PATH=${PATH}:/opt/jdk/bin \
    LANG=C.UTF-8

ADD imageFiles /
COPY --from=builder /opt/jdk /opt/jdk/.

RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
    adduser --uid 1337 --disabled-password --gecos "" --home "/home/${APP_USER}" "${APP_USER}" && \
    chmod 750 "/home/${APP_USER}"

RUN install-gosu.sh
