#!/bin/bash

export JENKINS_HOME=/var/lib/jenkins
export JENKINS_UC=https://updates.jenkins.io

set -e

yum install -y java-1.8.0-openjdk-devel

if ! rpm -qi jenkins > /dev/null ; then
	wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins.io/redhat-stable/jenkins.repo
	rpm --import http://pkg.jenkins.io/redhat-stable/jenkins.io.key

	yum install -y jenkins unzip zip
fi

perl -pe 's|JENKINS_PORT="8080"|JENKINS_PORT="8081"|' -i /etc/sysconfig/jenkins

install_plugin() {
	(TEMP_ALREADY_INSTALLED='' REF=$JENKINS_HOME/plugins ; . /tmp/install-jenkins-plugin.sh "$@" )
}

if [ ! -f $JENKINS_HOME/config.xml ]; then
	curl -L -o /tmp/install-jenkins-plugin.sh https://raw.githubusercontent.com/jenkinsci/docker/6eaa9b15926232310317490a3b9975ef61be763c/install-plugins.sh
	curl -L -o /usr/local/bin/jenkins-support https://raw.githubusercontent.com/jenkinsci/docker/6eaa9b15926232310317490a3b9975ef61be763c/jenkins-support
	mkdir -p /usr/share/jenkins
	ln -snf /usr/lib/jenkins/jenkins.war /usr/share/jenkins/jenkins.war

	SUGGESTED_PLUGINS="cloudbees-folder antisamy-markup-formatter build-timeout credentials-binding timestamper ws-cleanup ant gradle workflow-aggregator github-organization-folder pipeline-stage-view git subversion ssh-slaves matrix-auth pam-auth ldap email-ext mailer"

	install -d -o jenkins -g jenkins -m 755 "$JENKINS_HOME/plugins"

	install_plugin $SUGGESTED_PLUGINS
	install_plugin saml:0.6
	install_plugin role-strategy:2.3.2
	chown -R jenkins:jenkins $JENKINS_HOME/plugins

	rm -rf /usr/share/jenkins
	rm -f /tmp/install-jenkins-plugin.sh /usr/local/bin/jenkins-support

	install -o jenkins -g jenkins -m 644 /vagrant/provision/jenkins/config.xml $JENKINS_HOME/config.xml
fi

systemctl restart jenkins.service && systemctl enable jenkins.service
