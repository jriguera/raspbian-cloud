#!/bin/bash -e

on_chroot << EOF
apt-get -y purge xauth samba-common cifs-utils libnfsidmap2 nfs-common xdg-user-dirs triggerhappy
EOF

rm -rf "${ROOTFS_DIR}/etc/cifs-utils"
rm -f "${ROOTFS_DIR}/cifs.idmap.conf"
rm -f "${ROOTFS_DIR}/etc/request-key.d/cifs.spnego.conf"

rm -rf "${ROOTFS_DIR}/etc/samba"
rm -f "${ROOTFS_DIR}/etc/pam.d/samba"
rm -f "${ROOTFS_DIR}/etc/dhcp/dhclient-enter-hooks.d/samba"
rm -f "${ROOTFS_DIR}/etc/init.d/resize2fs_once"

# Attention: "  quietquiet" is on purpose in order to hack the greq in /usr/lib/raspi-config/init_resize.sh
# and keep quiet in the kernel cmd
install -m 644 files/cmdline.txt "${ROOTFS_DIR}/boot/"
# install -m 755 files/rc.local "${ROOTFS_DIR}/etc/"

rm -f "${ROOTFS_DIR}/etc/systemd/system/dhcpcd.service.d/wait.conf"
