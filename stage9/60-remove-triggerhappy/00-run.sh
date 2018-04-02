#!/bin/bash -e

# Uninstall
on_chroot << EOF
apt-get -y purge triggerhappy
rm -rf /etc/triggerhappy
EOF

