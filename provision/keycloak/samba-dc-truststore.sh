#!/bin/bash

TRUSTSTORE_PATH='/srv/keycloak/standalone/configuration/truststore.jks'

# 별도 truststore 사용시 시스템 CA를 자동으로 신뢰하지 않음.
# truststore 여러개 지정도 불가.
# 사용할 CA 인증서를 수동으로 추가

TRUSTED_CA_CERT_URLS="
file:/vagrant/shared/samba-dc-ldaps-ca.pem
https://pki.google.com/GIAG2.crt
"

for url in $TRUSTED_CA_CERT_URLS ; do
	tmpfile=$(mktemp)
	curl --silent --show-error --retry 5 --max-time 5 -o $tmpfile "$url"

	if [[ "$(head -1 $tmpfile)" == "-----BEGIN CERTIFICATE-----" ]]; then
		fingerprint=$(openssl x509 -in $tmpfile -outform der | openssl dgst -sha256 | cut -d' ' -f2)
	else
		fingerprint=$(openssl dgst -sha256 $tmpfile | cut -d' ' -f2)
	fi

	alias="$url#sha256=$fingerprint"
	
	yes | LANG=C keytool -import -keystore $TRUSTSTORE_PATH -storepass changeit -alias "$alias" -file $tmpfile || true
	
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
