#!/bin/bash

set -eu

gen_cert() {
	filename="$1"
	domain="$2"

	privkey="/etc/pki/tls/private/$filename.pem"
	cert="/etc/pki/tls/certs/$filename.pem"

	[ -f "$privkey" ] && return

	# 2048bit RSA 키 생성도 오래 걸려서 ECDSA 키 사용.
	# 실 사용이 아닌 데모 목적임.
	(umask 0077 && openssl ecparam -genkey -out "$privkey" -name prime256v1)

	openssl req -new -x509 -out "$cert" -key "$privkey" -days 3650 -sha256 -subj "/CN=$domain" -extensions v3_server -config <(
		cat /etc/pki/tls/openssl.cnf &&
		echo "[v3_server]
		basicConstraints = critical,CA:FALSE
		keyUsage = digitalSignature
		extendedKeyUsage = serverAuth
		subjectAltName=DNS:$domain,DNS:*.$domain"
	)

}

gen_cert "$1" "$2"
