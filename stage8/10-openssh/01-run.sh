#!/bin/bash -e

# Enable ssh
on_chroot << EOF
systemctl enable ssh
EOF

# Publish ssh in avahi
cp ${ROOTFS_DIR}/usr/share/doc/avahi-daemon/examples/ssh.service  ${ROOTFS_DIR}/etc/avahi/services/
