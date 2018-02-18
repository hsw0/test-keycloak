#!/bin/bash

SMB_CONF="/etc/samba/smb.conf"

set -eu

install -d -o root -g root -m 700 /data/samba

echo "Generating $SMB_CONF ..."

cat > "$SMB_CONF" <<EOF
[global]
server role = member server
private dir = /data/samba

realm = EXAMPLE.COM
workgroup = EXAMPLE
netbios name = radius-1234
server string = Radius Server
EOF


echo "done"
