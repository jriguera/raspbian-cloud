#!/bin/bash -e

on_chroot << EOF
apt-get -y purge samba-common cifs-utils libnfsidmap2 nfs-common
rm -rf /etc/cifs-utils /etc/request-key.d/cifs.idmap.conf /etc/request-key.d/cifs.spnego.conf
rm -rf /etc/samba /etc/pam.d/samba /etc/dhcp/dhclient-enter-hooks.d/samba
EOF

on_chroot << EOF
rm -f /etc/init.d/resize2fs_once
EOF

install -m 644 files/cmdline.txt	"${ROOTFS_DIR}/boot/"
install -m 755 files/rc.local		"${ROOTFS_DIR}/etc/"

rm -f "${ROOTFS_DIR}/etc/systemd/system/dhcpcd.service.d/wait.conf"

