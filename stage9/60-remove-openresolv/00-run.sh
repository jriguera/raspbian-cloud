#!/bin/bash -e

# Uninstall
on_chroot << EOF
apt-get -y purge openresolv
EOF

