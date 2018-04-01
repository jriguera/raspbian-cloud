#!/bin/bash -e

# Config
install -m 644 -g root -o root files/mailname ${ROOTFS_DIR}/etc/

# Systemd service
install -m 644 -g root -o root files/systemd/opensmtpd.service ${ROOTFS_DIR}/etc/systemd/system
