#!/bin/bash

TRUSTSTORE_PATH='/srv/keycloak/standalone/configuration/truststore.jks'

yes | LANG=C keytool -import -keystore $TRUSTSTORE_PATH -storepass changeit -alias samba-dc-ca -file <(cat /srv/samba-dc/data/tls/ca.pem) || true


# 별도 truststore 사용시 시스템 CA를 자동으로 신뢰하지 않음.
# truststore 여러개 지정도 불가.
# 사용할 CA 인증서를 수동으로 추가

TRUSTED_CA_CERT_URLS="
https://pki.google.com/GIAG2.crt
"

for url in $TRUSTED_CA_CERT_URLS ; do
	tmpfile=$(mktemp)
	curl -s -o $tmpfile "$url"
	yes | LANG=C keytool -import -keystore $TRUSTSTORE_PATH -storepass changeit -alias "$url" -file $tmpfile || true
	rm -f "$tmpfile"
done

grep -q '<spi name="truststore">' /srv/keycloak/standalone/configuration/standalone.xml ||
	perl -pe 's|(</theme>)|\1
            <spi name="truststore">
                <provider name="file" enabled="true">
                    <properties>
                        <property name="file" value="\${jboss.server.config.dir}/truststore.jks"/>
                        <property name="password" value="changeit"/>
                        <property name="hostname-verification-policy" value="WILDCARD"/>
                        <property name="disabled" value="false"/>
                    </properties>
                </provider>
            </spi>|' -i /srv/keycloak/standalone/configuration/standalone.xml


systemctl restart keycloak.service
