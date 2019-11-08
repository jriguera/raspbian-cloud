#!/bin/bash -e

# Install systemd settings
install -m 644 -g root -o root files/timesyncd.conf ${ROOTFS_DIR}/etc/systemd/
install -m 644 -g root -o root files/system.conf ${ROOTFS_DIR}/etc/systemd/
install -m 644 -g root -o root files/resolved.conf ${ROOTFS_DIR}/etc/systemd/
install -m 644 -g root -o root files/journald.conf ${ROOTFS_DIR}/etc/systemd/

# Enable systemd-timesyncd
on_chroot << EOF
# timedatectl set-ntp true
systemctl enable systemd-timesyncd
rm -f /etc/dhcp/dhclient-exit-hooks.d/timesyncd
EOF

# Add watchdog
# https://www.raspberrypi.org/forums/viewtopic.php?t=147501&p=972709
