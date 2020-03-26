#!/bin/bash -e

# config
install -m 644 -g root -o root files/main.conf /etc/bluetooth
install -m 644 -g root -o root files/default ${ROOTFS_DIR}/etc/default/bluetooth

# systemctl override
install -m 775 -g root -o root -d ${ROOTFS_DIR}/etc/systemd/system/bluetooth.service.d
install -m 644 -g root -o root files/systemd/override.conf ${ROOTFS_DIR}/etc/systemd/system/bluetooth.service.d

# Enable ssh
on_chroot << EOF
systemctl enable bluetooth
EOF

# Monit
install -m 775 -g root -o root -d ${ROOTFS_DIR}/etc/monit/conf-available/
install -m 644 -g root -o root files/monit/* ${ROOTFS_DIR}/etc/monit/conf-available/
on_chroot << EOF
mkdir -p /etc/monit/conf-enabled
cd /etc/monit/conf-enabled
ln -sf ../conf-available/bluetoothd
EOF
