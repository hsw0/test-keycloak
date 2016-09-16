#!/bin/bash

set -e

yum install -y nginx

cp -f /vagrant/provision/nginx/default.d/* /etc/nginx/default.d/
cp -f /vagrant/provision/nginx/conf.d/* /etc/nginx/conf.d/
ln -snf /var/log/nginx /usr/share/nginx/log

[ ! -f /etc/pki/tls/dhparam.pem ] && nohup openssl dhparam -out /etc/pki/tls/dhparam.pem 2048 &> /dev/null &

gen_cert() {
	filename="$1"
	domain="$2"

	privkey="/etc/pki/tls/private/$filename.pem"
	cert="/etc/pki/tls/certs/$filename.pem"

	[ -f "$privkey" ] && return

	(umask 0077 && openssl ecparam -genkey -out "$privkey" -name prime256v1)

	openssl req -new -x509 -out "$cert" -key "$privkey" -days 3650 -sha256 -subj "/CN=$domain" -extensions v3_server -config <(
		cat /etc/pki/tls/openssl.cnf &&
		echo "[v3_server]
		basicConstraints = critical,CA:FALSE
		keyUsage = digitalSignature, keyAgreement
		extendedKeyUsage = serverAuth
		subjectAltName=DNS:$domain,DNS:*.$domain"
	)

}

gen_cert default_server localhost
gen_cert example example.com
