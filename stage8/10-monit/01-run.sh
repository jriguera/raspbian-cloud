#!/bin/bash -e

# Configuration
install -m 600 -g root -o root files/monitrc ${ROOTFS_DIR}/etc/monit/
install -m 644 -g root -o root files/default ${ROOTFS_DIR}/etc/default/monit
mkdir -p ${ROOTFS_DIR}/etc/monit/conf.d
install -m 644 -g root -o root files/conf.d/* ${ROOTFS_DIR}/etc/monit/conf.d/
rm -f ${ROOTFS_DIR}/etc/monit/conf-available/*
install -m 644 -g root -o root files/conf-available/* ${ROOTFS_DIR}/etc/monit/conf-available/
install -m 644 -g root -o root files/templates/* ${ROOTFS_DIR}/etc/monit/templates/

# Systemd service
install -m 644 -g root -o root files/systemd/monit.service ${ROOTFS_DIR}/lib/systemd/system
on_chroot << EOF
systemctl enable monit
mkdir -p /etc/monit/conf-enabled
EOF

install -m 755 -g root -o root files/update-motd.d/* ${ROOTFS_DIR}/etc/update-motd.d/
install -m 755 -g root -o root files/bin/* ${ROOTFS_DIR}/usr/bin/
