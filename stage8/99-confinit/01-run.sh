#!/bin/bash -e

VERSION="$(cat confinit/VERSION)"
ARCH="arm6"

BOOT_CONFIG_FOLDER=/boot/config

# remove trailing slash
BOOT_CONFIG_FOLDER=${BOOT_CONFIG_FOLDER%%+(/)}
# start slash
BOOT_CONFIG_FOLDER=${BOOT_CONFIG_FOLDER##+(/)}

# copy configuration
cp -av config ${ROOTFS_DIR}/boot

# Install and enable confinit
on_chroot <<EOF
curl -sSL  https://github.com/jriguera/confinit/releases/download/v${VERSION}/confinit-${VERSION}-linux-${ARCH} -o /bin/confinit
chmod a+x /bin/confinit
EOF

# systemd units
install -m 644 -g root -o root confinit/systemd/confinit-boot@.service ${ROOTFS_DIR}/lib/systemd/system
install -m 644 -g root -o root confinit/systemd/confinit-final@.service ${ROOTFS_DIR}/lib/systemd/system
install -m 644 -g root -o root confinit/systemd/confinit.target ${ROOTFS_DIR}/lib/systemd/system

on_chroot <<EOF
# Enable service
mv "/lib/systemd/system/confinit-boot@.service" "/lib/systemd/system/confinit-boot@`systemd-escape --path ${BOOT_CONFIG_FOLDER}`.service"
mv "/lib/systemd/system/confinit-final@.service" "/lib/systemd/system/confinit-final@`systemd-escape --path ${BOOT_CONFIG_FOLDER}`.service"

# Enable target
systemctl enable confinit.target

systemctl enable "confinit-boot@`systemd-escape --path ${BOOT_CONFIG_FOLDER}`.service"
systemctl enable "confinit-final@`systemd-escape --path ${BOOT_CONFIG_FOLDER}`.service"
mkdir -p /${BOOT_CONFIG_FOLDER}
EOF
