#!/bin/bash

set -e

yum install -y epel-release

# User friendly
yum install -y tmux vim-enhanced man man-pages


/vagrant/provision/scripts/nginx.sh

/vagrant/provision/scripts/keycloak.sh

/vagrant/provision/scripts/jenkins.sh

/vagrant/provision/scripts/samba-dc.sh

/vagrant/provision/scripts/keycloak-samba.sh

while pgrep -f "openssl dhparam" > /dev/null ; do
	echo "Waiting openssl dhparam to be finished..."
	sleep 1;
done

systemctl restart nginx.service && systemctl enable nginx.service

echo Provision finished.
