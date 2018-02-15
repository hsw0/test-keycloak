#!/bin/bash

set -e

cp -f /vagrant/provision/nginx/conf.d/jenkins.conf /etc/nginx/conf.d/

systemctl restart nginx.service && systemctl enable nginx.service

# Install jenkins
/vagrant/provision/examples/jenkins/provision.sh
