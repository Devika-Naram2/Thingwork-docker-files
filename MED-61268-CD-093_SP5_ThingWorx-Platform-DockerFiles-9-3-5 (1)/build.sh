#!/bin/bash
source build.env

# determine the java version from the archive name
if [[ "$JAVA_ARCHIVE" =~ [0-9]+u[0-9]+ ]]; then
   JAVA_VERSION="${BASH_REMATCH[0]}"
   JAVA_PRODUCT_VERSION="${JAVA_VERSION%%u*}"
elif [[ "$JAVA_ARCHIVE" =~ [0-9]+(\.[0-9]+){2} ]]; then
   JAVA_VERSION="${BASH_REMATCH[0]}"
   JAVA_PRODUCT_VERSION="${JAVA_VERSION%%.*}"
else
  exit_status 1 "Unable to determine Java version from archive"
fi

# image tag
TAG_VERSION="java${JAVA_VERSION}-tomcat${TOMCAT_VERSION}"

TOMCAT_MAJOR_VERSION=${TOMCAT_VERSION%%.*}
TOMCAT_KEYS_URL=https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/KEYS
TOMCAT_TGZ_URL=https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz

exit_status () {
    if [ $1 -ne 0 ]; then
        echo "${2}: Failed."
        exit $1
    else
        echo "${2}: Success"
    fi
}

setup_build_dir () {
    if [ ! -d "$1" ]; then
        echo "Failed to find Dockerfile dir: $1"
        exit 1
    fi
    mkdir build
    cp -r staging build/.
    cp -r "$1/." build/.
}
clean_build_dir () {
    rm -rf build
}

download_files () {
    # tomcat
    (
        set -e
        cd staging

        curl -fSL ${TOMCAT_KEYS_URL} -o KEYS
        gpg --import KEYS

        if [ ! -e "${TOMCAT_ARCHIVE}" ]; then
            echo "Downloading Tomcat: ${TOMCAT_TGZ_URL}"
            curl -fSL ${TOMCAT_TGZ_URL} -o ${TOMCAT_ARCHIVE}
            curl -fSL ${TOMCAT_TGZ_URL}.asc -o ${TOMCAT_ARCHIVE}.asc
        fi
        gpg --verify ${TOMCAT_ARCHIVE}.asc ${TOMCAT_ARCHIVE}
    )
    exit_status $? "Download Tomcat"

    # mssql jdbc
    (
        cd staging
        if [ ! -e "${SQLDRIVER_FILE}" ]; then
            if [ ${SQLDRIVER_VERSION} != "7.4.1.0" ]; then
                echo "Can't Automatically Stage version ${SQLDRIVER_VERSION} due to changing URLs. Please manually download the MSSQL JDBC jar following README instructions."
                exit 1
            fi
            echo "Downloading mssql jdbc jar"
            curl -L -C - -O https://download.microsoft.com/download/6/9/9/699205CA-F1F1-4DE9-9335-18546C5C8CBD/sqljdbc_7.4.1.0_enu.tar.gz
        fi
    )
    exit_status $? "Download MSSQL JDBC Jar"
}

# Build Base
build_base () {
    setup_build_dir "dockerfiles/base"
    (
        cd build
        docker build --build-arg JAVA_VERSION=${JAVA_VERSION} \
        --build-arg JAVA_ARCHIVE=${JAVA_ARCHIVE} \
        --build-arg BASE_IMAGE=${BASE_IMAGE} \
        -t thingworx/base:${TAG_VERSION} \
        -t thingworx/base:latest \
        .
    )
    exit_status $? "Build Base"
    clean_build_dir
    return 0
}

# Build Platform Base
build_platform_base () {
    setup_build_dir "dockerfiles/platform/base"
    (
        cd build
        docker build --build-arg TAG_VERSION=${TAG_VERSION} \
        --build-arg TOMCAT_VERSION=${TOMCAT_VERSION} \
        --build-arg TOMCAT_ARCHIVE=${TOMCAT_ARCHIVE} \
        --build-arg LICENSE_FILE=${LICENSE_FILE} \
        --build-arg PLATFORM_SETTINGS_FILE=${PLATFORM_SETTINGS_FILE} \
        --build-arg TEMPLATE_PROCESSOR_ARCHIVE=${TEMPLATE_PROCESSOR_ARCHIVE} \
        --build-arg XMLMERGE_ARCHIVE=${XMLMERGE_ARCHIVE} \
        --build-arg BASE_IMAGE=${BASE_IMAGE} \
        -t thingworx/tw-platform-base:${TAG_VERSION} \
        -t thingworx/tw-platform-base:latest \
        .
    )
    exit_status $? "Build Platform Base"
    clean_build_dir
    return 0
}
# Build H2
build_h2 () {
    setup_build_dir "dockerfiles/platform/h2"
    (
        cd build
        docker build --build-arg TAG_VERSION=${TAG_VERSION} \
        --build-arg PLATFORM_ARCHIVE=${PLATFORM_H2_ARCHIVE} \
        --build-arg PLATFORM_VERSION=${PLATFORM_H2_VERSION} \
        --build-arg BASE_IMAGE=${BASE_IMAGE} \
        -t thingworx/platform-h2:${TAG_VERSION}-platform${PLATFORM_H2_VERSION} \
        -t thingworx/platform-h2:latest \
        .
    )
    exit_status $? "Build H2 Platform"
    clean_build_dir
    return 0
}
# Build PostgreSQL
build_postgres () {
    # Build postgresql-init Container
    setup_build_dir "dockerfiles/databases/postgres-init"
    (
        cd build
        docker build --build-arg PLATFORM_ARCHIVE=${PLATFORM_POSTGRES_ARCHIVE} \
        --build-arg PLATFORM_VERSION=${PLATFORM_POSTGRES_VERSION} \
        --build-arg BASE_IMAGE=${BASE_IMAGE} \
        -t thingworx/postgresql-init-twx:${TAG_VERSION}-platform${PLATFORM_POSTGRES_VERSION} \
        -t thingworx/postgresql-init-twx:latest \
        .
    )
    exit_status $? "Build Postgresql-init"
    clean_build_dir

    # Build TWX Platform
    setup_build_dir "dockerfiles/platform/postgres"
    (
        cd build
        docker build --build-arg TAG_VERSION=${TAG_VERSION} \
        --build-arg PLATFORM_ARCHIVE=${PLATFORM_POSTGRES_ARCHIVE} \
        --build-arg PLATFORM_VERSION=${PLATFORM_POSTGRES_VERSION} \
        --build-arg BASE_IMAGE=${BASE_IMAGE} \
        -t thingworx/platform-postgres:${TAG_VERSION}-platform${PLATFORM_POSTGRES_VERSION} \
        -t thingworx/platform-postgres:latest \
        .
    )
    exit_status $? "Build Postgres Platform"
    clean_build_dir
    return 0
}
# Build MSSQL
build_mssql () {
    # Build MSSQL-init Container
    setup_build_dir "dockerfiles/databases/mssql-init"
    (
        cd build
        docker build --build-arg PLATFORM_ARCHIVE=${PLATFORM_MSSQL_ARCHIVE} \
        --build-arg PLATFORM_VERSION=${PLATFORM_MSSQL_VERSION} \
        --build-arg BASE_IMAGE=${BASE_IMAGE} \
        -t thingworx/mssql-init-twx:${TAG_VERSION}-platform${PLATFORM_MSSQL_VERSION} \
        -t thingworx/mssql-init-twx:latest \
        .
    )
    exit_status $? "Build MSSQL-init DB"
    clean_build_dir

    # Build TWX Platform
    setup_build_dir "dockerfiles/platform/mssql"
    (
        cd build
        docker build --build-arg TAG_VERSION=${TAG_VERSION} \
        --build-arg PLATFORM_ARCHIVE=${PLATFORM_MSSQL_ARCHIVE} \
        --build-arg PLATFORM_VERSION=${PLATFORM_MSSQL_VERSION} \
        --build-arg SQLDRIVER_ARCHIVE=${SQLDRIVER_ARCHIVE} \
        --build-arg SQLDRIVER_VERSION=${SQLDRIVER_VERSION} \
        --build-arg BASE_IMAGE=${BASE_IMAGE} \
        -t thingworx/platform-mssql:${TAG_VERSION}-platform${PLATFORM_MSSQL_VERSION} \
        -t thingworx/platform-mssql:latest \
        .
    )
    exit_status $? "Build MSSQL Platform"
    clean_build_dir
    return 0
}

# Build Azure SQL
build_azuresql () {
    # Build Azuresql-init Container
        setup_build_dir "dockerfiles/databases/azuresql-init"
        (
            cd build
            docker build --build-arg PLATFORM_ARCHIVE=${PLATFORM_AZURESQL_ARCHIVE} \
            --build-arg PLATFORM_VERSION=${PLATFORM_AZURESQL_VERSION} \
            --build-arg BASE_IMAGE=${BASE_IMAGE} \
            -t thingworx/azuresql-init-twx:${TAG_VERSION}-platform${PLATFORM_AZURESQL_VERSION} \
            -t thingworx/azuresql-init-twx:latest \
            .
        )
        exit_status $? "Build Azuresql-init DB"
        clean_build_dir

    # Build TWX Platform
    setup_build_dir "dockerfiles/platform/azuresql"
    (
        cd build
        docker build --build-arg TAG_VERSION=${TAG_VERSION} \
        --build-arg PLATFORM_ARCHIVE=${PLATFORM_AZURESQL_ARCHIVE} \
        --build-arg PLATFORM_VERSION=${PLATFORM_AZURESQL_VERSION} \
        --build-arg SQLDRIVER_ARCHIVE=${AZURESQL_SQLDRIVER_ARCHIVE} \
        --build-arg SQLDRIVER_VERSION=${AZURESQL_SQLDRIVER_VERSION} \
        --build-arg BASE_IMAGE=${BASE_IMAGE} \
        -t thingworx/platform-azuresql:${TAG_VERSION}-platform${PLATFORM_AZURESQL_VERSION} \
        -t thingworx/platform-azuresql:latest \
        .
    )
    exit_status $? "Build AzureSQL Platform"
    clean_build_dir
    return 0
}

# Build all variants
build_all () {
    build_base
    build_platform_base
    build_h2
    build_postgres
    build_mssql
    build_azuresql
    return 0
}

clean_build_dir

if [ $# -lt 1 ]; then
    echo "No Arguments passed."
else
    if [ "$1" == "h2" ]; then
        build_base
        build_platform_base
        build_h2
    elif [ "$1" == "postgres" ]; then
        build_base
        build_platform_base
        build_postgres
    elif [ "$1" == "mssql" ]; then
        build_base
        build_platform_base
        build_mssql
    elif [ "$1" == "azuresql" ]; then
        build_base
        build_platform_base
        build_azuresql
    elif [ "$1" == "all" ]; then
        build_all
    elif [ "$1" == "stage" ]; then
        download_files
    else
        echo "Unknown option, not building."
        exit 1
    fi
fi
