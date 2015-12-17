#!/bin/bash

. /vagrant/provision/scripts/common.sh

systemctl stop postfix.service
systemctl disable postfix.service

yum_install epel-release
yum_install tmux
yum_install vim-enhanced gcc gcc-c++ automake autoconf patch libtool git
yum_install unzip man man-pages
yum_install nmap bind-utils
