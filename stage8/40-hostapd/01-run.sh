#!/bin/bash -e

DEVICE=wlan0

install -m 644 -g root -o root files/default ${ROOTFS_DIR}/etc/default/hostapd

# Systemd service
install -m 644 -g root -o root files/systemd/hostapd@.service ${ROOTFS_DIR}/lib/systemd/system

on_chroot <<EOF
# Enable service
systemctl enable hostapd@${DEVICE}.service
EOF

