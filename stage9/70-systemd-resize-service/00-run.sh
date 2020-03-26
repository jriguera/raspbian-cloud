#!/bin/bash -e

# Install script
install -m 755 -g root -o root files/bin/* ${ROOTFS_DIR}/bin/

# Systemd unit
install -m 644 -g root -o root files/systemd/resize-rootfs.service ${ROOTFS_DIR}/lib/systemd/system


if [ "${USE_QEMU}" = "1" ]; then
	on_chroot << EOF
systemctl disable resize-rootfs.service
EOF
else
	on_chroot << EOF
systemctl enable resize-rootfs.service
EOF
fi

