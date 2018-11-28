#!/bin/bash -e

DATA_VOLUME=/media/volume-data/data

# remove trailing slash
DATA_VOLUME=${BACKUP_VOLUME%%+(/)}
# start slash
DATA_VOLUME=${BACKUP_VOLUME##+(/)}

# Copy binary
install -m 755 -g root -o root rpi-btrfs/bin/* ${ROOTFS_DIR}/bin
install -m 755 -g root -o root rpi-btrfs/requirements.txt ${ROOTFS_DIR}/tmp

# Monit
install -m 775 -g root -o root -d ${ROOTFS_DIR}/etc/monit/conf.d
install -m 644 -g root -o root files/monit/* ${ROOTFS_DIR}/etc/monit/conf.d/

## Install requiremets
on_chroot <<EOF
pip3 install -r /tmp/requirements.txt
rm -f /tmp/requirements.txt
EOF

on_chroot <<EOF
# Enable backups with betterclone
systemctl enable betterclone-backup.target
systemctl enable betterclone-restore.target
systemctl enable "betterclone-restore@`systemd-escape --path ${DATA_VOLUME}`.service"
systemctl enable "betterclone-backup@`systemd-escape --path ${DATA_VOLUME}`.timer"
EOF

