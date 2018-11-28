#!/bin/bash -e

install -m 644 -g root -o root files/default ${ROOTFS_DIR}/etc/default/rng-tools

# Systemd service
install -m 644 -g root -o root files/systemd/rng-tools.service ${ROOTFS_DIR}/etc/systemd/system

on_chroot <<EOF
systemctl enable rng-tools
EOF

# Remove unneeded files
rm -rf ${ROOTFS_DIR}/etc/logcheck

# Monit
install -m 775 -g root -o root -d ${ROOTFS_DIR}/etc/monit/conf-available/
install -m 644 -g root -o root files/monit/* ${ROOTFS_DIR}/etc/monit/conf-available/
on_chroot << EOF
mkdir -p /etc/monit/conf-enabled
cd /etc/monit/conf-enabled
ln -sf ../conf-available/rngd
EOF

