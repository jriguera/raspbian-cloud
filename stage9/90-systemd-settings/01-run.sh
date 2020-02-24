#!/bin/bash -e

# Install systemd settings
install -m 644 -g root -o root files/system.conf ${ROOTFS_DIR}/etc/systemd/
install -m 644 -g root -o root files/journald.conf ${ROOTFS_DIR}/etc/systemd/

# Disable rsyslog
on_chroot << EOF
systemctl disable rsyslog
EOF

# Add watchdog
# https://www.raspberrypi.org/forums/viewtopic.php?t=147501&p=972709
