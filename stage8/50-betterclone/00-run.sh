#!/bin/bash -e

BACKUP_VOLUME=/mnt/volume/data

# remove trailing slash
BACKUP_VOLUME=${BACKUP_VOLUME%%+(/)}
# start slash
BACKUP_VOLUME=${BACKUP_VOLUME##+(/)}

# Copy default configuration
mkdir -p ${ROOTFS_DIR}/etc/betterclone/
mkdir -p ${ROOTFS_DIR}/boot/etc/betterclone/
install -m 644 -g root -o root betterclone/etc/config.env ${ROOTFS_DIR}/boot/etc/betterclone/

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
systemctl enable betterclone-restore@`systemd-escape --path ${BACKUP_VOLUME}`.service
systemctl enable betterclone-backup@`systemd-escape --path ${BACKUP_VOLUME}`.timer
systemctl enable betterclone-backup@`systemd-escape --path ${BACKUP_VOLUME}`.service
EOF

