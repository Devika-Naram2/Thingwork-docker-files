# ThingWorx Foundation Dockerfiles

## Overview
This package provides a set of Dockerfiles and supplemental scripts required to
build Docker images for ThingWorx Foundation. Dockerfiles and scripts are
provided for the following content providers:

* H2
* PostgreSQL
* Microsoft SQL Server
* Azure SQL

While there are very simple examples on how to run the images built here more in
depth examples can be found in the ThingWorx Docker Guide on the PTC Support
Downloads site alongside this release.

## Prerequisites
This topic covers the supported operating systems and required Docker software
to run ThingWorx Docker images.

### Operating System
Docker images can be run on any platform supporting Docker.

Building the Docker images is supported only for Linux operating systems. The
scripts have been validated on Ubuntu and should work on other Linux
operating systems that support Docker and Docker Compose. Note that PTC has
not validated other systems.

### Docker Versions
The following Docker versions are required:

* Docker Community Edition (docker-ce)

    Version 19 or higher is recommended. To install the Docker Community
    Edition on your system, follow the instructions for your operating system on
    the Docker web site: https://www.docker.com/community-edition#/download.

* Docker Compose (docker-compose)

    Version 1.25 or higher is recommended. To install the Docker Compose on
    your system, follow the instructions for your operating system on the Docker
    web site: https://docs.docker.com/compose/install/.## Setting Up For ThingWorx Ignite Docker Builds

In order to build the Thingworx Ignite Docker images there are two major
steps that need to be done. The first is to make sure the needed binaries are
staged and available for the build process and the second is to verify & modify, if required, the
`build.env` variable file with appropriate values.

## Setting Up For ThingWorx Docker Builds
In order to build the ThingWorx foundation Docker images there are two major
steps that need to be done. The first is to make sure the needed binaries are
staged and available for the build process and the second is to modify the
`build.env` variable file with appropriate values. Additionally if you are going to
run ThingWorx HA in a clustered mode there are extra required images described below
that must be built and available in your repository.

### Required Files
In order for the variables and staging to make sense, knowing what files are
required first will help.

#### All Platform Versions
* template-processor

    This PTC provided program parses templates inside the Docker container when
    starting to inject variables and format configuration files based on the
    running environment. Example File:
    `template-processor-12.2.1.21-application.tar.gz`

* xmlmerge

    This PTC provided program for merging xml documents inside the Docker container
    when processing XML configurations. Example File:
    `xmlmerge-12.2.1.21-application.tar.gz`

* tomcat

    The Tomcat artifact obtained from Apache to run the ThingWorx Platform.
    Example File: `tomcat-9.0.43.tar.gz`

* java

    The Java JDK 11. Example File: `jdk-11.0.10_linux-x64_bin.tar.gz`

#### H2
* ThingWorx Platform H2

    Example File: `Thingworx-Platform-H2-9.3.5-b1258.zip`

#### PostgreSQL
* ThingWorx Platform PostgreSQL

    Example File: `Thingworx-Platform-Postgres-9.3.5-b1258.zip`

#### MSSQL
* ThingWorx Platform MSSQL

    Example File: `Thingworx-Platform-Mssql-9.3.5-b1258.zip`

* MS SQL JDBC Driver

    The JDBC Driver for MS SQL obtained from Microsoft, Example File:
    `sqljdbc_7.4.1.0_enu.tar.gz`

#### Azure SQL
* ThingWorx Platform Azure SQL

    Example File: `Thingworx-Platform-Azuresql-9.3.5-b1258.zip`

* MS SQL JDBC Driver

    The JDBC Driver for MS SQL obtained from Microsoft, Example File:
    `sqljdbc_7.4.1.0_enu.tar.gz`

### `build.env` Variables
The following are a list of variables in `build.env` that must be set.

| Variable                   | Default                                                        | Comment                                                                                                                               |
|----------------------------|----------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| BASE_IMAGE                 | ubuntu:20.04                                                   | The version of ubuntu to use as base image                                                                                             |
| JAVA_ARCHIVE               | amazon-corretto-11.0.10.9.1-linux-x64.tar.gz                   | The archive of the Java SDK 11 package from 'staging' JDK.                                                                                                   |
| TOMCAT_VERSION             | 9.0.63                                                         | The Apache Tomcat Version                                                                                                             |
| TEMPLATE_PROCESSOR_VERSION | 12.2.1.21                                     | The version of the template-processor archive as it exists in the `staging` folder.                                                   |
| XMLMERGE_VERSION | 12.2.1.21                                     | The version of the xmlmerge archive as it exists in the `staging` folder.                                                   |
| PLATFORM_SETTINGS_FILE     | platform-settings.json                                         | The path to a base ThingWorx settings file. This is included in the `staging` directory.                                              |
| PLATFORM_H2_VERSION        | 9.3.5-b1258                                        | The version of the ThingWorx H2 Platform to build. Only required when building H2 containers.                                         |
| PLATFORM_H2_ARCHIVE        | Thingworx-Platform-H2-9.3.5-b1258.zip       | The file name of the ThingWorx H2 zip as it exists in the `staging` directory. Only required when building H2 containers.             |
| PLATFORM_POSTGRES_VERSION  | 9.3.5-b1258                                        | The version of the ThingWorx Postgres Platform to build. Only required when building Postgres containers.                             |
| PLATFORM_POSTGRES_ARCHIVE  | Thingworx-Platform-Postgres-9.3.5-b1258.zip | The file name of the ThingWorx Postgres zip as it exists in the `staging` directory. Only required when building Postgres containers. |
| PLATFORM_MSSQL_VERSION     | 9.3.5-b1258                                        | The version of the ThingWorx MSSQL Platform to build. Only required when building MSSQL containers.                                   |
| PLATFORM_MSSQL_ARCHIVE     | Thingworx-Platform-Mssql-9.3.5-b1258.zip    | The file name of the ThingWorx MSSQL zip as it exists in the `staging` directory. Only required when building MSSQL containers.       |
| SQLDRIVER_VERSION          | 7.4.1.0                                                   | The version to install of the MS SQL JDBC Driver. Only required when building MSSQL containers.                                       |
| PLATFORM_AZURESQL_VERSION     | 9.3.5-b1258                                        | The version of the ThingWorx Azure SQL Platform to build. Only required when building Azure SQL containers.                                   |
| PLATFORM_AZURESQL_ARCHIVE     | Thingworx-Platform-Azuresql-9.3.5-b1258.zip    | The file name of the ThingWorx Azure SQL zip as it exists in the `staging` directory. Only required when building Azure SQL containers.       |
| AZURESQL_SQLDRIVER_VERSION          | 7.4.1.0                                                   | The version to install of the MS SQL JDBC Driver. Only required when building Azure SQL containers.                                       |

The following are a list of other variables in `build.env` which only need to be
modified if the default patterns do not match the files placed in the `staging`
directory.

| Variable          | Default                                 | Comment                                                                                                                         |
|-------------------|-----------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| TOMCAT_ARCHIVE    | tomcat-${TOMCAT_VERSION}.tar.gz         | The file name of the Tomcat archive as it exists in the `staging` directory.                                                    |
| SQLDRIVER_ARCHIVE | sqljdbc_${SQLDRIVER_VERSION}_enu.tar.gz | The file name of the MS SQL JDBC archive as it exists in the `staging` directory. Only required when building MSSQL containers. |
| AZURESQL_SQLDRIVER_ARCHIVE | sqljdbc_${AZURESQL_SQLDRIVER_VERSION}_enu.tar.gz | The file name of the MS SQL JDBC archive as it exists in the `staging` directory. Only required when building Azure SQL containers. |
| TEMPLATE_PROCESSOR_ARCHIVE | template-processor-${TEMPLATE_PROCESSOR_VERSION}-application.tar.gz | The file name of the template-processor archive as it exists in the `staging` folder.|
| SECURITY_TOOL_ARCHIVE | security-common-cli-${SECURITY_TOOL_VERSION}-application.tar.gz | The file name of the security tool archive as it exists in the `staging` folder.|

### Staging Files
You must put the required files for building the Docker images in the `staging`
folder that is part of this release. The `staging` folder should already contain a
base `platform-settings.json` file.

To assist with staging, Apache Tomcat and the configured version of the Microsoft
JDBC Driver for SQL Server (the default version) can be downloaded automatically.

To download automatically:
* Make sure you have set the `build.env` file variables appropriately.
* Run the command `./build.sh stage`.
If there are no errors, the files should be in the `staging` folder and they
should match your `build.env` settings.

#### Java
Any supported version of Java 11 can be used. Choose to download the Linux x64 tar.gz.
For example: `jdk-11.0.10_linux-x64_bin.tar.gz`

Save this file into the `staging` directory and make sure the `JAVA_ARCHIVE`
variable is set in `build.env` match.

#### ThingWorx Platform Archives
The ThingWorx Platform Archives can be downloaded from the PTC Support Downloads
site alongside this Dockerfile release. Make sure to use same ThingWorx version
as this set of Dockerfiles as there could be differences. Example File:
`Thingworx-Platform-H2-9.3.5-b1258.zip`

Save this file into the `staging` directory and make sure the `PLATFORM_*_VERSION`
and `PLATFORM_*_ARCHIVE` variables match the file.

#### Template Processor Archive
The template-processor program is included in the `staging` directory and should
be included in the Docker builds automatically. Double check the version and
archive file name in `staging` match your `build.env` settings.

#### Security Tool Archive
The security-tool program is included in the `staging` directory and should
be included in the Docker builds automatically. Double check the version and
archive file name in `staging` match your `build.env` settings.

#### Tomcat Archive
If the attempt to automatically download Tomcat does not work it can be downloaded
directly from Apache at the following link: [Tomcat 9 Downloads](https://tomcat.apache.org/download-90.cgi)
Choose to download the `Core` version and get the `tar.gz`. Example File: `apache-tomcat-9.0.43.tar.gz`

Save this file into the `staging` directory and make sure the `TOMCAT_VERSION`
and `TOMCAT_ARCHIVE` variables in `build.end` match.

#### MS SQL JDBC Driver
If the attempt to automatically download the MS SQL JDBC Driver doesn't work, or
an alternate version is desired it can be obtained from [Microsoft JDBC Driver 6.0](https://www.microsoft.com/en-us/download/details.aspx?id=11774)
Choose to download the English version (as the file structure differs with
alternate languages). One the following screen, select `sqljdbc_<version>_enu.tar.gz`
and click Next.

Save this file into the `staging` directory and make sure the `SQLDRIVER_VERSION`,
`SQLDRIVER_ARCHIVE`, `AZURESQL_SQLDRIVER_VERSION`, and `AZURESQL_SQLDRIVER_ARCHIVE`
variables in `build.env` match as needed.

## Building The ThingWorx Foundation Images
With the setup complete, it is now possible to run the build script to create the
Docker images.

The included `build.sh` script is able to take the variables set previously and
work with the `staging` directory to make sure the Docker build command has the
appropriate variables and build context passed in.

To build the images run the command: `./build.sh <type>`
`type` can be any one of the following: `h2`, `postgres`, `mssql`, or `azuresql`.

After the build process completes there will be Docker images available depending
on the content provider you built.

* H2

    Platform Docker Image: `thingworx/platform-h2:latest`

* PostgreSQL

    Platform Docker Image: `thingworx/platform-postgres:latest`
    PostgreSQL init Docker Image: `thingworx/postgresql-init:latest`

* MSSQL

    Platform Docker Image: `thingworx/platform-mssql:latest`
    MS SQL init Docker Image: `thingworx/mssql-init:latest`

* Azure SQL

    Platform Docker Image: `thingworx/platform-azuresql:latest`
    AZURE SQL init Docker Image: `thingworx/azuresql-init:latest`

**NOTE** The init Docker Images for PostgreSQL, MSSQL and AzureSQL must be run before platform images.

## ThingWorx HA additional images
In order to run ThingWorx HA in a clustered configuration there are some supporting
images required. They are built separately to these ThingWorx foundation images, and
can be found in the Ignite & CXServer Docker Guides on the PTC Support Downloads site alongside
this release.

* Ignite
    Ignite Docker Image: `thingwork/ignite-twx:latest`

* CXServer

    CXServer Docker Image: `thingwork/cxserver-twx:latest`

* HAProxy

    HAProxy Docker Image: `haproxy:2.0.14`
    For HAProxy we use the official docker image configured with a custom
    configuration file. A configuration example can be found in `conf/haproxy.cfg`.
    Once the container is up and running the haproxy  administration page is available
    at `http://{haproxy-host}:1936/` and the credentials can be configured with
    `HAPROXY_STAT_USER` and `HAPROXY_STAT_PASSWORD` docker environment variables.

## Using and Running the ThingWorx Docker Images
Included in this release are some basic Docker Compose files intended to help
test the build ThingWorx Images.

#### Licensing
There are three options for configuring licensing in the docker environment. You
can either authenticate to the PTC Licensing server and automatically download a license,
include your orgs `license.bin` in the docker container, or start the ThingWorx platform
container in limited mode with a trial license.

To use server authentication uncomment the following environment variables in the docker-compose.yml file:
```
    LS_USERNAME: ${PTCUSERNAME}
    LS_PASSWORD: ${PTCPASSWORD}
```
Replace ${PTCUSERNAME} and ${PTCPASSWORD} with your user name and password for the PTC Support site.
This downloads the license file to your /ThingworxPlatform folder.

If you want to include your `license.bin` file then place it in the same directory as the `docker-compose.yml`
file, and uncomment the following lines belonging to the platform service in the docker compose file.
```
# Use this to mount your orgs license file, if not ThingWorx will fallback to temporary licence
volumes:
  - ./mylicense.bin:/ThingworxPlatform/license.bin
```

#### Authentication & Authorization
There is sample config for SSL communication between services that is commented out in the
docker compose files. This includes environment variables, JVM flags, and a persistent
volume to store certs. There is more detailed information around these environment variables
in the table below.

Authorization can be configured between Zookeeper and its clients using kerberos. There are
details about the environment variables needed in the table below.  

###Standalone

To start the compose environment, you can run `docker-compose -f docker-compose-<type>.yml up -d`
`type` can be any one of the following: `h2`, `postgres`, `mssql`, or `azuresql`.

For example, to start, view the logs, and stop the H2 image:
```
docker-compose -f docker-compose-h2.yml up -d
docker-compose -f docker-compose-h2.yml logs -f
<ctrl-c>
docker-compose -f docker-compose-h2.yml down
```

###HA Cluster
Sample docker compose environments are provided for postgres, mssql, and azuresql
persistence providers in the `docker-compose-<persistenceProvider>-clustered` folders.

**NOTE:** If using the database provisioning built into the platform container then you
cannot start multiple platforms simultaneously on first startup. Only one platform can
be started which will provision the database, after this is completed the other platforms
can be brought up.

There are three files used to stand up the environment.

* .env

    This file contains all of the environment variables used by the various services.
    There are optional variables for SSL between services that are marked with comments.

* docker-compose.override.yml

    This file defines dependencies on service start order. For example if ThingWorx
    platform starts before zookeeper is ready to accept connections there will be errors.

* docker-compose.yml

    Sample docker-compose file used to define the environment. Here we define our volumes
    & services along with some extra variables. There is reference SSL configuration services
    that is optional and therefore commented out.

#### `.env` Variables
The following are a list of variables in `.env` that must be set.

| Variable                   | Default                                                        | Comment                                                                                                                               |
|----------------------------|----------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| - Zookeeper | | |
| ZOOKEEPER_IMAGE_VERSION   | 3.6.3 | Tag for the zookeeper image |
| ZK_PORT   | 2181  | Port that clients will use to connect to zookeeper |
| - Ignite | | |
| IGNITE_IMAGE_TAG  | latest | Tag for the ignite image |
| - Persistence Provider-init | | |
| TWX_DATABASE_USERNAME | No default set | User used to connect to the persistence provider |
| TWX_DATABASE_PASSWORD | No default set | Password for user used to connect to the persistence provider |
| TWX_DATABASE_SCHEMA   | No default set | Name of the schema where database has been setup |
| DATABASE_ADMIN_USERNAME | No default set | Database administrator user name |
| DATABASE_ADMIN_PASSWORD | No default set | Database administrator password |
| DATABASE_ADMIN_SCHEMA | No default set | Name of the default database created by administrator |
| - ThingWorx Platform | | |
| PLATFORM_IMAGE_TAG    | latest    | Tag for platform and init image    |
| HTTP_PORT | 8080  | HTTP port for platform |
| HTTP_SERVICE_NAME | thingworx-http    | HTTP service name for platform |
| PLATFORM_HTTP_ACTIVE  | true | Enable HTTP for platform |
| - Connection Server | | |
| CXSERVER_IMAGE_TAG    | latest    | Tag for connection server image |
| SECRET_CX_APP_KEY | No default set    | Application key that connection server will use to connect to ThingWorx |
| SECRET_PROVISIONING_APP_KEY | No default set | Application key used for provisioning ThingWorx on first startup |

The following are a list of optional variables in `.env` that are related to SSL.

| Variable                   | Default                                                        | Comment                                                                                                                               |
|----------------------------|----------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| - HAProxy | | |
| HAPROXY_SSL_ENABLED        | false    | Enable SSl for HAProxy                                                                                                                |
| - Zookeeper | | |
| ZK_SSL_ENABLED            | true      | Enable SSL for zookeeper |
| ZK_SSL_PORT               | 2281      | HTTPS port for zookeeper |
| ZK_SSL_KEYSTORE_LOCATION  | No default value set  | Path to the zookeeper keystore can be stored in certs volume e.g /certs/zookeeper.p12 |
| ZK_SSL_KEYSTORE_PASSWORD  | No default value set  | Password for zookeeper keystore |                                        
| ZK_SSL_TRUSTSTORE_LOCATION    | No default value set  | Path for the zookeeper truststore can be stored in certs volume e.g /certs/zookeeper-truststore.p12 |
| ZK_SSL_TRUSTSTORE_PASSWORD    | No default value set  | Password for zookeeper keystore |
| ZK_SASL_ENABLED   | false | Enable SASL authentication in Zookeeper |
| ZK_SASL_SECURITY_AUTH_LOGIN_CONFIG    | /conf/jaas.conf | Path to JAAS configuration file |
| ZK_SASL_SECURITY_KRB5_CONF    | /conf/krb5.conf |  Path to Kerberos configuration file |
| - Ignite | | |
| IGNITE_SSL_ACTIVE | true  | Enable SSL for Ignite |
| IGNITE_KEYSTORE_FILE_PATH | No default value set  | Path to the ignite keystore, can be stored in certs volume e.g /certs/ignite.pfx |
| IGNITE_KEYSTORE_PASSWORD  | No default value set  | Password for ignite keystore |
| - ThingWorx Platform | | |
| HTTPS_PORT    | 8443  | HTTPS port for ThingWorx |
| HTTPS_SERVICE_NAME    | thingworx-https   | Service name for HTTPS ThingWorx |
| PLATFORM_HTTPS_ACTIVE | true  | Enable HTTPS on ThingWorx |
| PLATFORM_SSL_KEYSTORE_FILE_PATH   | /certs    | Folder for the platform keystore, can use certs volume |
| PLATFORM_SSL_KEYSTORE_FILE_NAME   | No default value set  | Platform keystore file e.g. platform.pfx |
| PLATFORM_SSL_KEYSTORE_PASSWORD    | No default value set  | Password for platform keystore |
| TOMCAT_SSL_PROTOCOLS    | TLSv1.2  | The SSL protocol for Tomcat to use. |
| TOMCAT_SSL_CIPHERS    | No default value set  | Optional list of comma separated cipher suites. Will limit HTTPS connections to only these ciphers listed. If not set the default JVM ciphers will be used.  |
| - Connection Server | | |
| ENABLE_CLUSTERED_MODE | false | Enable Clustered Mode for connection server|
| CXSERVER_HTTPS_ACTIVE | true  | Enable HTTPS for connection server |
| CXSERVER_SSL_ENABLED  | true      | Enable SSL for connection server |
| CXSERVER_SSL_KEYSTORE_LOCATION    | No default value set  | Path to the cxserver keystore can be stored in certs volume e.g /certs/connectionserver.p12 |
| CXSERVER_SSL_KEYSTORE_PASSWORD    | No default value set  | Password for cxserver keystore |
| CXSERVER_SSL_TRUSTSTORE_LOCATION  | No default value set  | Path for the cxserver truststore can be stored in certs volume e.g /certs/connectionserver-truststore.p12 |
| CXSERVER_SSL_TRUSTSTORE_PASSWORD  | No default value set  | Password for cxserver keystore |
| CXSERVER_SSL_CLIENT_AUTH_MODE | none  | Connection server client authorization mode |
| - Postgres | | |
| PGSSLMODE: | false | Enable SSL for Postgres communication |
| PGSSLCERT: | No default value set | Path to postgres certificate e.g /certs/pgcert.crt |
| PGSSLKEY: | No default values set | Path to postgres certificate key |

The following are a list of optional variables in `.env` that are related to Tomcat.

| Variable                         | Default                                   | Comment                                                                                                    |
|----------------------------------|-------------------------------------------|------------------------------------------------------------------------------------------------------------|
| TOMCAT_CONNECTION_TIMEOUT        | 20000                                     | The number of milliseconds this Connector will wait for the request URI line to be presented.              |
| TOMCAT_MAX_CONNECTIONS           | 10000                                     | The maximum number of connections that the server will accept and process at any given time.               |
| TOMCAT_MAX_THREADS               | 200                                       | The maximum number of request processing threads to be created by this Connector.                          |
| TOMCAT_COMPRESSION               | off                                       | The Connector may use HTTP/1.1 GZIP compression in an attempt to save server bandwidth.                    |
| TOMCAT_COMPRESSION_MIN_SIZE      | 2048                                      | Used to specify the minimum amount of data before the output is compressed                                 |
| TOMCAT_USE_SEND_FILE             | true                                      | Tomcat connector sendfile capability                                                                       |
| TOMCAT_ACCESS_LOGGING_CLASS_NAME | org.apache.catalina.valves.AccessLogValve | The class name of the implementation to use for access logging.                                            |
| TOMCAT_ACCESS_LOGGING_PREFIX     | localhost_access_log                      | The prefix added to the start of each log file's name.                                                     |
| TOMCAT_ACCESS_LOGGING_SUFFIX     | .txt                                      | The suffix added to the end of each log file's name.                                                       |
| TOMCAT_ACCESS_LOGGING_PATTERN    | %h %l %u %t &quot;%r&quot; %s %b %D       | A formatting layout identifying the various information fields from the request and response to be logged. |

To bring up the clustered environment simple navigate to your preferred persistence providers folder
and execute the following commands.
```
# Start full cluster
docker-compose up -d

# Start only specified services (will still respect docker-compose.override.yml dependencies)
docker-compose up -d postgresql ignite zookeeper platform1

# Check container logs
docker-compose logs -f platform1

# Stop and remove specific container
docker-compose rm -s ignite

# Stop and remove all containers
docker-compose down

# Stop and remove all containers, including cleaning volumes.
# This cleans the database, removes /ThingworxStorage, etc.
docker-compose down -v
```

This guide is mainly targeting the building of the Docker Images. For more detailed
usage examples and configuration please see the full documentation that can be
found in the ThingWorx Docker Guide on the PTC Support Downloads site alongside
this release.
