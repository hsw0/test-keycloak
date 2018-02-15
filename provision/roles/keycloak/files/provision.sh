#!/bin/bash

# 이 스크립트 파일의 경로
cd "$( dirname "${BASH_SOURCE[0]}" )"

set -eu


# Initial provision
if [ -f /srv/keycloak/data/keycloak.mv.db ]; then
	echo "Already provisioned"
	exit 0
fi

PROVISION_CONTAINER_NAME=keycloak-provision

admin_password='admin'
echo "Initial admin account:"
echo "Login: admin"
echo "Password: $admin_password"

echo "Launching provisioning container"

docker run --rm --name "$PROVISION_CONTAINER_NAME" \
	--env KEYCLOAK_USER=admin \
	--env "KEYCLOAK_PASSWORD=$admin_password" \
	--volume /srv/keycloak/data:/opt/jboss/keycloak/standalone/data \
	--volume /vagrant/provision/keycloak/example-realm.json:/tmp/example-realm.json:ro \
	keycloak:latest \
	-Dkeycloak.import=/tmp/example-realm.json  &

sleep 45

if [[ $(docker inspect "$PROVISION_CONTAINER_NAME" --format '{{.State.Status}}') != "running" ]]; then
	echo "Provisioning container is failed!" >&2
	exit 1
fi

i=0
max_retries=300
while ! docker exec "$PROVISION_CONTAINER_NAME" /opt/jboss/keycloak/bin/jboss-cli.sh --connect command=:shutdown ; do
	echo "Waiting provisioning job to be finished. ($i/$max_retries)"
	sleep 1
	i=$((i+1))

	if [[ $i -ge $max_retries ]]; then
		echo "Too many retries"
		break
	fi

	if [[ $(docker inspect "$PROVISION_CONTAINER_NAME" --format '{{.State.Status}}') != "running" ]]; then
		echo "Provisioning container is stopped" >&2
		break
	fi
done
