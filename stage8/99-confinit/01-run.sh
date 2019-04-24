#!/bin/bash -e

VERSION="0.3.2"
ARCH="arm6"

BOOT_CONFIG_FOLDER=/boot/config

# remove trailing slash
BOOT_CONFIG_FOLDER=${BOOT_CONFIG_FOLDER%%+(/)}
# start slash
BOOT_CONFIG_FOLDER=${BOOT_CONFIG_FOLDER##+(/)}

# copy configuration
cp -av config ${ROOTFS_DIR}/boot

# Install and enable Prometheus node_exporter
on_chroot <<EOF
curl -sSL  https://github.com/jriguera/confinit/releases/download/v${VERSION}/confinit-${VERSION}-linux-${ARCH} -o /bin/confinit
chmod a+x /bin/confinit
EOF

# systemd units
install -m 644 -g root -o root confinit/systemd/confinit@.service ${ROOTFS_DIR}/lib/systemd/system

on_chroot <<EOF
# Enable service
mv "/lib/systemd/system/confinit@.service" "/lib/systemd/system/confinit@`systemd-escape --path ${BOOT_CONFIG_FOLDER}`.service"
systemctl enable "confinit@`systemd-escape --path ${BOOT_CONFIG_FOLDER}`.service"
mkdir -p /${BOOT_CONFIG_FOLDER}
EOF
