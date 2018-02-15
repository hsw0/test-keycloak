#!/bin/bash

set -e

DOMAIN="$(hostname --domain | tr '[a-z]' '[A-Z]')"
DC_HOSTNAME="$(hostname --fqdn)"
DC_VOLUME="/var/lib/samba/private"
ADMIN_PASSWD='admin'
PROVISION_USERNAME="__vagrant-provision\$"
PROVISION_KEYTAB="$DC_VOLUME/__vagrant_provision.keytab"

export DEBIAN_FRONTEND='noninteractive'

if ! host archive.ubuntu.com &> /dev/null ; then
	echo 'nameserver 8.8.8.8' > /etc/resolv.conf
fi

# http://serverfault.com/a/425237
now=$(date +%s)
apt_cache_update_ts=$(stat -c '%Y' /var/lib/apt/periodic/update-success-stamp 2>/dev/null || echo 0)
if (( $now - $apt_cache_update_ts > 86400 )) ; then
	apt-get update
fi


# apt-get install 직후 자동시작 방지
# http://askubuntu.com/a/501622
cat > /usr/sbin/policy-rc.d <<EOF
#!/bin/sh
if pgrep -f 'apt-get install' > /dev/null ; then
	echo "Skipping autostart during apt-get install"
	exit 101
fi
EOF
chmod a+x /usr/sbin/policy-rc.d

apt-get install -y --no-install-recommends \
	samba samba-dsdb-modules samba-vfs-modules winbind \
	krb5-user ldap-utils libsasl2-modules-gssapi-mit

# /tmp/krb5cc_$uid 파일로 저장 방지.
export KRB5CCNAME=KEYRING:session:provision

# virtualbox NAT nic는 Host, VM간 통신이 불가능.
# JVM (or Keycloak?) LDAP 클라이언트는 한 도메인에 접속불가,접속가능 2개의
# 레코드가 있을 경우 처음 접속 실패시 fallback하지 않고 바로 중단하는 것으로 보임
echo -e "\n[global]\n\tinterfaces = lo 192.168.33.224.0/24" > /etc/samba/smb.conf.local

# samba 데몬 시작 대기. 가끔 KDC/DNS는 시작되었는데 LDAP가 늦게 뜨는 등 타이밍 문제가 있음.
wait_daemon_start() {
	local max_retries=50
	local errmsg=''

	for i in $(seq $max_retries) ; do
		if kinit -k -t "$PROVISION_KEYTAB" "$PROVISION_USERNAME@$DOMAIN" ; then
			kdestroy
			break
		elif (( $i == $max_retries )) ; then
			echo "samba (KDC) start failed" >&2
			return 1
		fi
		
		echo "Waiting samba (KDC) to start... ($i/$max_retries)"
		sleep 1
	done

	for i in $(seq $max_retries) ; do
		if ldapsearch -h "$DC_HOSTNAME" -x -s "base" -b "" -LLL currentTime &> /dev/null ; then
			break
		elif (( $i == $max_retries )) ; then
			echo "samba (KDC) start failed" >&2
			return 1
		fi

		echo "Waiting samba (LDAP) to start... ($i/$max_retries)"
		sleep 1
	done
}

needs_provision=$(test ! -f "$PROVISION_KEYTAB" && echo true || echo false)
if [ "$needs_provision" == "true" ]; then
	echo "Provisioning domain controller"

	rm -f /etc/samba/smb.conf

	random_admin_passwd=$(uuidgen)

	samba-tool domain provision \
		--realm="$DOMAIN" \
		--domain="${DOMAIN%%.*}" \
		--adminpass="$random_admin_passwd" \
		--use-rfc2307 \
		--use-xattr=auto

	grep -q 'include = /etc/samba/smb.conf.local' /etc/samba/smb.conf ||
		echo -e "\n[global]\n\tinclude = /etc/samba/smb.conf.local" >> /etc/samba/smb.conf

	# 추후 프로비저닝 작업용으로 사용할 별도 관리자 계정 생성
	# Administrator 계정 암호를 바꾸더라도 문제 없도록 함.
	# samba-tool user/group/domain 명령은 DB 파일에 직접 접근하여 데몬을 시작하지 않아도 동작.
	samba-tool user add "$PROVISION_USERNAME" --random-password --use-username-as-cn
	samba-tool group addmembers 'Domain Admins' "$PROVISION_USERNAME"
	samba-tool group addmembers 'Schema Admins' "$PROVISION_USERNAME"
	samba-tool group addmembers 'Enterprise Admins' "$PROVISION_USERNAME"
	samba-tool user setexpiry --noexpiry "$PROVISION_USERNAME"
	samba-tool domain exportkeytab "$PROVISION_KEYTAB" --principal="$PROVISION_USERNAME"

	# Set Administrator password
	samba-tool domain passwordsettings set \
		--complexity=off \
		--min-pwd-age=0 \
		--history-length=0 \
		--min-pwd-length=4

	samba-tool user setexpiry --noexpiry Administrator

	echo 'nameserver 127.0.0.1' > /etc/resolv.conf

	systemctl start samba-ad-dc.service
	wait_daemon_start

	echo -ne "$random_admin_passwd\n$ADMIN_PASSWD\n$ADMIN_PASSWD" |
		kpasswd "Administrator@$DOMAIN"
else
	echo "Domain controller already provisioned."
fi

# 프로비저닝 스크립트를 여러 번 수행할 경우를 고려.

echo 'nameserver 127.0.0.1' > /etc/resolv.conf
systemctl start samba-ad-dc.service
wait_daemon_start

systemctl enable samba-ad-dc.service

kinit -k -t "$PROVISION_KEYTAB" "$PROVISION_USERNAME@$DOMAIN"

server="$DC_HOSTNAME"
basedn=$(ldapsearch -h $server -x -s "base" -b "" -LLL defaultNamingContext | sed -n 's/^\s*defaultNamingContext:\s*\(.*\)/\1/p')

# 이미 존재할 경우는 무시. 일일히 exit(68) 체크하기 귀찮아 에러 통으로 무시...
set +e

< /vagrant/provision/samba-dc/create-ou.ldif.tpl sed -e "s/\\\$BASEDN/$basedn/g" |
	ldapadd -h "$server" -Y GSSAPI -v -c


. /vagrant/provision/samba-dc/adduser.sh

basedn="OU=World,$basedn"

ad_useradd "OU=Users,$basedn" 'hsw@syscall.io' 'test' '길동' '홍'
ad_useradd "OU=Users,$basedn" 'test1@example.com' 'test' '꺽정' '임'
ad_useradd "OU=Users,$basedn" 'test2@example.com' 'test' '길산' '장'

ad_groupadd "OU=Groups,$basedn" 'CI Admin' 'ci-admin'
ad_groupadd "OU=Groups,$basedn" 'CI Login' 'ci-login'

ad_groupmems add 'ci-admin' 'hsw'
ad_groupmems add 'ci-login' 'test1'
ad_groupmems add 'ci-login' 'test2'

set -e

kdestroy
