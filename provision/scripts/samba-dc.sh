#!/bin/bash

# Samba 4 AD DC 구성.
# RHEL 계열에는 Kerberos 라이브러리 관련 문제로 도메인 컨트롤러가 빠져 있어 
# 어쩔 수 없이 Ubuntu docker 이미지 사용.

DOMAIN="EXAMPLE.COM"
DC_HOSTNAME="dc1.$DOMAIN"
DC_IPADDR="172.16.0.16"
DC_SUBNET="172.16.0.0/16"
DC_VOLUME="/srv/samba-dc"

ADMIN_PASSWD='admin'
RANDOM_ADMIN_PASSWD=$(uuidgen)

needs_provision=$(test ! -d "$DC_VOLUME/data" && echo true)

set -e

# dnsmasq 섳정
# Samba DC를 DNS resolver로 지정시 DC가 죽어있을 경우 외부 DNS 조회 실패를 방지하기 위해 
# dnsmasq를 resolver로 설정

yum install -y dnsmasq

echo "server=8.8.8.8
server=/$DOMAIN/$DC_IPADDR
no-resolv
" > /etc/dnsmasq.d/local.conf

systemctl restart dnsmasq.service && systemctl enable dnsmasq.service
echo 'nameserver 127.0.0.1' > /etc/resolv.conf

perl -pe "s/(PEERDNS)=[\"']?yes[\"']?/\1=no/" -i /etc/sysconfig/network-scripts/ifcfg-*
grep -q 'DNS1=127.0.0.1' /etc/sysconfig/network ||
	echo 'DNS1=127.0.0.1' >> /etc/sysconfig/network

yum install -y docker
yum install -y krb5-workstation cyrus-sasl-gssapi openldap-clients

systemctl restart docker.service && systemctl enable docker.service

docker build --tag=samba-dc /vagrant/provision/samba-dc

docker inspect --format="{{ .State.Running }}" samba-dc &> /dev/null &&
	docker rm -f samba-dc 2> /dev/null

docker network inspect net0 &> /dev/null &&
	docker network rm net0 2> /dev/null

docker network create \
	--subnet="$DC_SUBNET" \
	--opt com.docker.network.bridge.enable_ip_masquerade=true \
	--opt com.docker.network.bridge.enable_icc=true \
	net0

docker run \
	--detach \
	--net=net0 \
	--hostname="$DC_HOSTNAME" \
	--ip="$DC_IPADDR" \
	--dns=8.8.8.8 \
	--volume="$DC_VOLUME/etc:/etc/samba" \
	--volume="$DC_VOLUME/data:/var/lib/samba/private" \
	--env REALM="$DOMAIN" \
	--env INITIAL_ADMIN_PASSWD="$RANDOM_ADMIN_PASSWD" \
	--restart=always \
	--name samba-dc \
	samba-dc

if [ "$needs_provision" == "true" ]; then
	while ! ldapsearch -h "$DC_HOSTNAME" -x -s "base" -b "" -LLL currentTime &> /dev/null ; do
	echo "Waiting provision to be finished"
	sleep 1
	done

	BASEDN=$(ldapsearch -h "$DC_HOSTNAME" -x -s "base" -b "" -LLL defaultNamingContext | sed -n 's/^\s*defaultNamingContext:\s*\(.*\)/\1/p')

	echo -ne "$RANDOM_ADMIN_PASSWD\n$ADMIN_PASSWD\n$ADMIN_PASSWD" |
		kpasswd "Administrator@$DOMAIN"

	echo "$ADMIN_PASSWD" | kinit "Administrator@$DOMAIN"

	ldapadd -h "$DC_HOSTNAME" -Y GSSAPI -v -f /vagrant/provision/samba-dc/create-ou.ldif

	/vagrant/provision/samba-dc/adduser.sh

	kdestroy
fi
