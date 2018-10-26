#!/bin/bash -e

BOOT_CONFIG_FOLDER=/boot/etc

# remove trailing slash
BOOT_CONFIG_FOLDER=${BOOT_CONFIG_FOLDER%%+(/)}
# start slash
BOOT_CONFIG_FOLDER=${BOOT_CONFIG_FOLDER##+(/)}

# script
install -m 755 -g root -o root files/bin/cp-files-permissions.sh ${ROOTFS_DIR}/usr/local/bin

# systemd units
install -m 644 -g root -o root files/systemd/cp-files-permissions@.service ${ROOTFS_DIR}/lib/systemd/system

on_chroot <<EOF
# Enable service
systemctl enable cp-files-permissions@`systemd-escape --path ${BOOT_CONFIG_FOLDER}`.service
mkdir -p /${BOOT_CONFIG_FOLDER}
EOF

