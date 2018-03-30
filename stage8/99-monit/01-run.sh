#!/bin/bash -e

# Configuration
install -m 644 -g root -o root files/monitrc ${ROOTFS_DIR}/etc/monit
install -m 644 -g root -o root files/default ${ROOTFS_DIR}/etc/default/monit
mkdir -p ${ROOTFS_DIR}/etc/monit/conf.d
install -m 644 -g root -o root files/conf.d/* ${ROOTFS_DIR}/etc/monit/conf.d
rm -f ${ROOTFS_DIR}/etc/monit/conf-available/*
install -m 644 -g root -o root files/conf-available/* ${ROOTFS_DIR}/etc/monit/

# Systemd service
install -m 644 -g root -o root files/systemd/monit.service ${ROOTFS_DIR}/etc/systemd/system
on_chroot << EOF
systemctl enable monit
# Enable services
mkdir -p /etc/monit/conf-enabled
cd /etc/monit/conf-enabled
ln -s ../conf-available/dnsmasq
ln -s ../conf-available/docker
ln -s ../conf-available/node_exporter
ln -s ../conf-available/opensmtpd
ln -s ../conf-available/openssh-server
EOF
