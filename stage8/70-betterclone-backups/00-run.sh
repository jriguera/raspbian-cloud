#!/bin/bash -e

# Copy binary
install -m 755 -g root -o root betterclone/bin/betterclone ${ROOTFS_DIR}/bin

# Copy default configuration
mkdir -p ${ROOTFS_DIR}/etc/betterclone/
install -m 644 -g root -o root betterclone/etc/config.env ${ROOTFS_DIR}/etc/betterclone/

# Betterclone services
install -m 644 -g root -o root betterclone/systemd/betterclone-backup.target ${ROOTFS_DIR}/lib/systemd/system
install -m 644 -g root -o root betterclone/systemd/betterclone-backup@.service ${ROOTFS_DIR}/lib/systemd/system
install -m 644 -g root -o root betterclone/systemd/betterclone-backup@.timer ${ROOTFS_DIR}/lib/systemd/system
install -m 644 -g root -o root betterclone/systemd/betterclone-restore.target ${ROOTFS_DIR}/lib/systemd/system
install -m 644 -g root -o root betterclone/systemd/betterclone-restore@.service ${ROOTFS_DIR}/lib/systemd/system

on_chroot <<EOF
# Enable services
systemctl enable betterclone-backup.target
systemctl enable betterclone-restore.target
EOF
