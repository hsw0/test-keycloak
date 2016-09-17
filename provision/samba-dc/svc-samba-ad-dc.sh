#!/bin/bash

install -o root -g root -m 755 -d /var/run/samba

echo 'nameserver 127.0.0.1' > /etc/resolv.conf

exec /usr/sbin/samba --interactive
