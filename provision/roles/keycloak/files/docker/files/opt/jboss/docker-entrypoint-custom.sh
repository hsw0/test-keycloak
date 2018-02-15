#!/bin/bash

# Keycloak custom truststore 관리
#
# 주의: 별도 truststore 사용시 시스템 CA를 자동으로 신뢰하지 않음.
# truststore 파일을 여러개 지정도 불가.
# 사용할 CA 인증서를 모두 추가할 것.

_load_truststore() {
	local TRUSTSTORE_PATH="$JBOSS_HOME/standalone/configuration/truststore.jks"
	local TRUSTSTORE_SRC_PATH="$JBOSS_HOME/standalone/configuration/truststore"

	# 재시작시 store 초기화
	cp -f /etc/pki/java/emptystore.jks "$TRUSTSTORE_PATH"


	# http://mywiki.wooledge.org/BashFAQ/020
	while IFS= read -r -d $'\0' file ; do
		echo "Importing certificate $file"

		local alias="$(basename "$file")"
		
		yes | LANG=C keytool -import -keystore $TRUSTSTORE_PATH -storepass changeit -alias "$alias" -file "$file" || true
	done < <(find "$TRUSTSTORE_SRC_PATH" -type f -print0)
}

_load_truststore

exec "/opt/jboss/docker-entrypoint.sh" $@
