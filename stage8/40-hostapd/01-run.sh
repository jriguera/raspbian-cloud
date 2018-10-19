#!/bin/bash -e

install -m 644 -g root -o root files/default ${ROOTFS_DIR}/etc/default/hostapd

# Systemd service
install -m 644 -g root -o root files/systemd/hostapd@.service ${ROOTFS_DIR}/etc/systemd/system
