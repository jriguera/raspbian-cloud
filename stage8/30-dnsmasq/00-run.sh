#!/bin/bash -e

install -m 644 -g root -o root files/default ${ROOTFS_DIR}/etc/default/dnsmasq
install -m 644 -g root -o root files/dnsmasq.conf ${ROOTFS_DIR}/etc/dnsmasq.conf

# Systemd service
install -m 644 -g root -o root files/systemd/dnsmasq.service ${ROOTFS_DIR}/etc/systemd/system
on_chroot << EOF
rm -f /lib/systemd/system/dnsmasq.service
systemctl enable dnsmasq
EOF
