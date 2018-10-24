#!/bin/bash -e

DEVICE=wlan0

install -m 644 -g root -o root files/default ${ROOTFS_DIR}/etc/default/hostapd

# Systemd service
install -m 644 -g root -o root files/systemd/hostapd@.service ${ROOTFS_DIR}/etc/systemd/system

on_chroot <<EOF
ln -sfr /etc/systemd/system/hostapd@.service /etc/systemd/system/hostapd@${DEVICE}.service
# Enable services
systemctl enable hostapd@${DEVICE}.service
EOF

