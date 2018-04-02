#!/bin/bash -e

# Uninstall
on_chroot << EOF
apt-get -y purge isc-dhcp-client isc-dhcp-common
rm -rf /etc/dhcp/
EOF

