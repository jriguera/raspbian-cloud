#!/bin/bash -e

# Disable bluetooth SAP plugin (SIM Access Profile)
mkdir -p ${ROOTFS_DIR}/etc/systemd/system/bluetooth.service.d
install -m 644 -g root -o root files/systemd/override.conf ${ROOTFS_DIR}/etc/systemd/system/bluetooth.service.d
