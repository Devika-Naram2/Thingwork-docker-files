#!/bin/bash

# As of Tomcat 9.0.29 the CATALINA_OPTS are surrounded by quotes in catalina.sh
CATALINA_OPTS="-Dserver -Dd64\
 -XX:+UseNUMA\
 -Djsse.enableSNIExtension=${ENABLE_SNI}\
 -Djava.net.preferIPv4Stack=true\
 -Dcom.sun.management.jmxremote\
 -Dcom.sun.management.jmxremote.port=${JMX_ADDRESS}\
 -Dcom.sun.management.jmxremote.rmi.port=${JMX_ADDRESS}\
 -Dcom.sun.management.jmxremote.ssl=false\
 -Dcom.sun.management.jmxremote.authenticate=false\
 -Dcom.sun.management.jmxremote.host=${JMX_REMOTE_HOST}\
 -Djava.rmi.server.hostname=${JMX_RMI_HOSTNAME}\
 -DTHINGWORX_STORAGE=${THINGWORX_STORAGE}\
 -XX:HeapDumpPath=${THINGWORX_STORAGE}/logs\
 -Dfile.encoding=UTF-8\
 -Djava.library.path=${CATALINA_BASE}/webapps/Thingworx/WEB-INF/extensions\
 -Dlog4j2.formatMsgNoLookups=true\
 ${CATALINA_OPTS}"

echo "CATALINA_OPTS=$CATALINA_OPTS"
