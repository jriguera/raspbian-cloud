#!/bin/bash -e

# Copy binary
install -m 755 -g root -o root rpi-btrfs/bin/* ${ROOTFS_DIR}/bin
install -m 755 -g root -o root rpi-btrfs/requirements.txt ${ROOTFS_DIR}/tmp

## Install docker-compose
on_chroot <<EOF
pip3 install -r /tmp/requirements.txt
rm -f /tmp/requirements.txt
EOF

