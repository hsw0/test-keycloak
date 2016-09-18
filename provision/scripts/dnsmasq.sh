#!/bin/bash

# dnsmasq를 로컬 DNS resolver로 설정

. /vagrant/provision/scripts/common.sh

yum_install dnsmasq

DOMAIN="$1"
RESOLVER="$2"

echo "server=8.8.8.8
server=/$DOMAIN/$RESOLVER
no-resolv
" > /etc/dnsmasq.d/local.conf

systemctl restart dnsmasq.service && systemctl enable dnsmasq.service

echo 'nameserver 127.0.0.1' > /etc/resolv.conf

perl -pe "s/(PEERDNS)=[\"']?yes[\"']?/\1=no/" -i /etc/sysconfig/network-scripts/ifcfg-*
grep -q 'DNS1=127.0.0.1' /etc/sysconfig/network ||
	echo 'DNS1=127.0.0.1' >> /etc/sysconfig/network
