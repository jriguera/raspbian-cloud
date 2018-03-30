#!/bin/bash -e

# Install systemd 
install -m 644 -g root -o root files/timesyncd.conf ${ROOTFS_DIR}/etc/systemd/
install -m 644 -g root -o root files/system.conf ${ROOTFS_DIR}/etc/systemd/
install -m 644 -g root -o root files/resolved.conf ${ROOTFS_DIR}/etc/systemd/
install -m 644 -g root -o root files/journald.conf ${ROOTFS_DIR}/etc/systemd/

# Enable systemd-timesyncd
on_chroot << EOF
systemctl enable systemd-timesyncd
timedatectl set-ntp true
EOF

# Add watchdog
# https://www.raspberrypi.org/forums/viewtopic.php?t=147501&p=972709
