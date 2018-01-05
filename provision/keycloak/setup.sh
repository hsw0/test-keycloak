#!/bin/bash

KEYCLOAK_VERSION=3.4.3.Final
KEYCLOAK_ARCHIVE_NAME="keycloak-$KEYCLOAK_VERSION.tar.gz"
KEYCLOAK_ARCHIVE_PATH="/vagrant/shared/$KEYCLOAK_ARCHIVE_NAME"

. /vagrant/provision/scripts/common.sh

set -e

yum_install java-1.8.0-openjdk-headless

if ! id keycloak &> /dev/null ; then
	useradd --no-create-home --home-dir /srv/keycloak --system --shell /sbin/nologin keycloak
fi

if [ ! -e /srv/keycloak ]; then
	if [ ! -f "$KEYCLOAK_ARCHIVE_PATH" ]; then
		curl -L -o "$KEYCLOAK_ARCHIVE_PATH" "https://downloads.jboss.org/keycloak/$KEYCLOAK_VERSION/$KEYCLOAK_ARCHIVE_NAME"
	fi

	tar zxvf "$KEYCLOAK_ARCHIVE_PATH" -C /srv
	ln -snf /srv/keycloak-* /srv/keycloak
fi

perl -pe 's|<http-listener name="default" socket-binding="http" redirect-socket="https"/>|<http-listener name="default" socket-binding="http" redirect-socket="https" proxy-address-forwarding="true" />|' -i /srv/keycloak/standalone/configuration/standalone.xml
perl -pe 's|<host name="default-host" alias="localhost">|<host name="default-host" alias="localhost" default-web-module="keycloak-server.war">|' -i /srv/keycloak/standalone/configuration/standalone.xml
perl -pe 's|<location name="/" handler="welcome-content"/>||' -i /srv/keycloak/standalone/configuration/standalone.xml

chown -R root:root /srv/keycloak

install -d -o keycloak -g keycloak -m 755 /srv/keycloak/standalone/configuration
install -d -o keycloak -g keycloak -m 755 /srv/keycloak/standalone/deployments
install -d -o keycloak -g keycloak -m 755 /srv/keycloak/standalone/data
install -d -o keycloak -g keycloak -m 755 /srv/keycloak/standalone/tmp
chown -R keycloak:keycloak /srv/keycloak/standalone/{configuration,data,tmp,deployments}

if [ "$(readlink /srv/keycloak/standalone/log)" != "/var/log/keycloak" ]; then
	rm -rf /srv/keycloak/standalone/log
	install -d -o keycloak -g keycloak -m 755 /var/log/keycloak
	ln -snf /var/log/keycloak /srv/keycloak/standalone/log
fi


if [ ! -e /srv/keycloak/standalone/data/keycloak.h2.db ]; then
	admin_password='admin'
	/srv/keycloak/bin/add-user-keycloak.sh --user admin --password "$admin_password"
	echo "Initial admin account:"
	echo "Login: admin"
	echo "Password: $admin_password"
	unset admin_password

	echo "Importing example realm"
	sudo -u keycloak /srv/keycloak/bin/standalone.sh -Dkeycloak.import=/vagrant/provision/keycloak/example-realm.json  &
	sleep 30
	while ! /srv/keycloak/bin/jboss-cli.sh --connect command=:shutdown ; do
		echo "Waiting keycloak import job to be finished."
		sleep 1
	done
fi

cp -f /vagrant/provision/keycloak/keycloak.service /etc/systemd/system/
systemctl daemon-reload

systemctl restart keycloak.service &&
	systemctl enable keycloak.service
