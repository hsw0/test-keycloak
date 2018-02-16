ARG KEYCLOAK_VERSION=3.4.3.Final
FROM jboss/keycloak:${KEYCLOAK_VERSION}

# Customize
USER root

ADD files /

# Build custom keystore
RUN set -eux && \
    keytool -keystore /etc/pki/java/emptystore.jks -storetype JKS -storepass changeit -genkey -alias dummy -keyalg RSA -keysize 2048 -dname CN=invalid -keypass invalid && \
    keytool -keystore /etc/pki/java/emptystore.jks -storepass changeit -delete -alias dummy && \
    cp /etc/pki/java/emptystore.jks $JBOSS_HOME/standalone/configuration/truststore.jks && \
    mkdir $JBOSS_HOME/standalone/configuration/truststore

VOLUME ["/opt/jboss/keycloak/standalone/configuration/truststore"]

# Drop permission
USER jboss

RUN set -eux && \
    cd /opt/jboss/keycloak && \
    bin/jboss-cli.sh --file=cli/customization/standalone-configuration.cli && \
    bin/jboss-cli.sh --file=cli/customization/standalone-ha-configuration.cli && \
    rm -rf /opt/jboss/keycloak/standalone/configuration/standalone_xml_history


VOLUME ["/opt/jboss/keycloak/standalone/data"]


ENTRYPOINT [ "/opt/jboss/docker-entrypoint-custom.sh" ]
CMD ["-b", "0.0.0.0"]
