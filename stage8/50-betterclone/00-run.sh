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
install -m 644 -g root -o root betterclone/systemd/betterclone-backup.target ${ROOTFS_DIR}/etc/systemd/system
install -m 644 -g root -o root betterclone/systemd/betterclone-backup@.service ${ROOTFS_DIR}/etc/systemd/system
install -m 644 -g root -o root betterclone/systemd/betterclone-backup@.timer ${ROOTFS_DIR}/etc/systemd/system
install -m 644 -g root -o root betterclone/systemd/betterclone-restore.target ${ROOTFS_DIR}/etc/systemd/system
install -m 644 -g root -o root betterclone/systemd/betterclone-restore@.service ${ROOTFS_DIR}/etc/systemd/system

on_chroot <<EOF
VOLUME=$(systemd-escape --path ${BACKUP_VOLUME})
ln -sfr /etc/systemd/system/betterclone-backup@.service /etc/systemd/system/betterclone-backup@${VOLUME}.service
ln -sfr /etc/systemd/system/betterclone-backup@.timer /etc/systemd/system/betterclone-backup@${VOLUME}.timer
ln -sfr /etc/systemd/system/betterclone-restore@.service /etc/systemd/system/betterclone-restore@${VOLUME}.service
# Enable services
systemctl enable betterclone-backup.target
systemctl enable betterclone-restore.target
systemctl enable betterclone-restore@${VOLUME}.service
systemctl enable betterclone-backup@${VOLUME}.service
EOF

