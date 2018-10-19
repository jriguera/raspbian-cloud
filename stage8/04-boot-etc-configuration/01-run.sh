#!/bin/bash -e

# script
install -m 755 -g root -o root files/bin/cp-files-permissions.sh ${ROOTFS_DIR}/usr/local/bin

# systemd units
install -m 644 -g root -o root files/systemd/cp-files-permissions@.service ${ROOTFS_DIR}/etc/systemd/system
# /boot folder services
install -m 644 -g root -o root files/systemd/cp-files-permissions@.service ${ROOTFS_DIR}/etc/systemd/system/cp-files-permissions@boot-etc.service

