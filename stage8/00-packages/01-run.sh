#!/bin/bash -e

# Locale settings
install -m 644 -g root -o root files/default ${ROOTFS_DIR}/etc/default/locale
install -m 644 -g root -o root files/locale.gen ${ROOTFS_DIR}/etc/locale.gen
on_chroot << EOF
locale-gen
EOF



