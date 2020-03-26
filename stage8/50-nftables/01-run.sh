#!/bin/bash -e

mkdir -p ${ROOTFS_DIR}/etc/systemd/system/nftables.service.d
install -m 644 -g root -o root files/systemd/nftables.conf ${ROOTFS_DIR}/etc/systemd/system/nftables.service.d

mkdir -p ${ROOTFS_DIR}/etc/nftables

on_chroot <<EOF
# Enable service
systemctl enable nftables.service
EOF
