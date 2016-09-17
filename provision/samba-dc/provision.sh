#!/bin/bash

# 이미 프로비저닝 되어 있는지 확인
[ -f /var/lib/samba/private/sam.ldb ] && exit 0

. /etc/container_environment.sh

rm -f /etc/samba/smb.conf

samba-tool domain provision \
	--realm="$REALM" \
	--domain="${REALM%%.*}" \
	--adminpass="$INITIAL_ADMIN_PASSWD" \
	--use-rfc2307 \
	--use-xattr=auto

rm -f /etc/container_environment/INITIAL_ADMIN_PASSWD

samba-tool domain passwordsettings set \
	--complexity=off \
	--min-pwd-age=0 \
	--history-length=0 \
	--min-pwd-length=4

samba-tool user setexpiry --noexpiry Administrator
