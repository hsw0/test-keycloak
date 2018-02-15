#!/bin/bash

set -e

cp -f /vagrant/provision/nginx/conf.d/keycloak.conf /etc/nginx/conf.d/

systemctl restart nginx.service && systemctl enable nginx.service

# Install & Provision keycloak
/vagrant/provision/keycloak/setup.sh

/vagrant/provision/keycloak/samba-dc-truststore.sh
