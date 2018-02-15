#!/bin/bash

export JENKINS_HOME=/var/lib/jenkins
export JENKINS_UC=https://updates.jenkins.io

set -e

perl -pe 's|JENKINS_PORT="8080"|JENKINS_PORT="8081"|' -i /etc/sysconfig/jenkins

install_plugin() {
	(TEMP_ALREADY_INSTALLED='' REF=$JENKINS_HOME/plugins ; . /tmp/install-jenkins-plugin.sh "$@" )
}

if [ -f $JENKINS_HOME/config.xml ]; then
	echo "Already provisioned"
	exit 0
fi

curl -L -o /tmp/install-jenkins-plugin.sh https://raw.githubusercontent.com/jenkinsci/docker/6eaa9b15926232310317490a3b9975ef61be763c/install-plugins.sh
curl -L -o /usr/local/bin/jenkins-support https://raw.githubusercontent.com/jenkinsci/docker/6eaa9b15926232310317490a3b9975ef61be763c/jenkins-support
mkdir -p /usr/share/jenkins
ln -snf /usr/lib/jenkins/jenkins.war /usr/share/jenkins/jenkins.war

SUGGESTED_PLUGINS="cloudbees-folder antisamy-markup-formatter build-timeout credentials-binding timestamper ws-cleanup ant gradle workflow-aggregator github-organization-folder pipeline-stage-view git subversion ssh-slaves matrix-auth pam-auth ldap email-ext mailer"

install -d -o jenkins -g jenkins -m 755 "$JENKINS_HOME/plugins"

retries=5
for i in $(seq $retries) ; do
	rm -rf $JENKINS_HOME/plugins/*.lock
	install_plugin $SUGGESTED_PLUGINS saml:0.6 role-strategy:2.3.2 &&
		break

	if (( $i <= $retries )); then
		echo "Plugin install failed. retrying $i/$retries.." >&2
	else
		echo "Max retries exceeded" >&2
		exit 1
	fi
done

chown -R jenkins:jenkins $JENKINS_HOME/plugins

rm -rf /usr/share/jenkins
rm -f /tmp/install-jenkins-plugin.sh /usr/local/bin/jenkins-support

install -o jenkins -g jenkins -m 644 /vagrant/provision/examples/jenkins/config.xml $JENKINS_HOME/config.xml
