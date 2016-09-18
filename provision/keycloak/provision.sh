#!/bin/bash

set -e

. /vagrant/provision/scripts/common.sh

yum_install epel-release

# User friendly
yum_install tmux vim-enhanced man-db man-pages


# Install nginx
/vagrant/provision/nginx/provision.sh

cp -f /vagrant/provision/nginx/conf.d/keycloak.conf /etc/nginx/conf.d/

systemctl restart nginx.service && systemctl enable nginx.service

# Samba DC를 DNS resolver로 직접 지정시 DC가 죽은 경우
# 패키지 설치, 외부 IDP 로그인시 외부 DNS 조회 실패를 방지하기 위해
# dnsmasq를 Split-horizon DNS 용으로 사용
/vagrant/provision/scripts/dnsmasq.sh "$(hostname --domain)" 192.168.33.224

# Install & Provision keycloak
/vagrant/provision/keycloak/setup.sh

/vagrant/provision/keycloak/samba-dc-truststore.sh
