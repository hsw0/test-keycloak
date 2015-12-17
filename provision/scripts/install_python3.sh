#!/bin/bash

. /vagrant/provision/scripts/common.sh

SCL_PYTHON34_REPO='https://www.softwarecollections.org/en/scls/rhscl/rh-python34/epel-7-x86_64/download/rhscl-rh-python34-epel-7-x86_64.noarch.rpm'
rpm -qi --quiet "rhscl-rh-python34-epel-7-x86_64" || yum localinstall "$SCL_PYTHON34_REPO"

yum_install rh-python34-python-virtualenv
