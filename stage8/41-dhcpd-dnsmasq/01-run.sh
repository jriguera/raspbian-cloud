#!/bin/bash -e

install -m 644 -g root -o root files/* ${ROOTFS_DIR}/etc/

on_chroot << EOF
cd /etc/dhcp/dhclient-exit-hooks.d
ln -s ../../dhcpcd.exit-hook
EOF
