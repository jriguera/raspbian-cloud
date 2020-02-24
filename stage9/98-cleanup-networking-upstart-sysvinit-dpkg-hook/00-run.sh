#!/bin/bash -e

# dpkg hooks to delete unneeded folders sysvinit and upstart, because of the fact of using systemd as default init
install -m 644 -g root -o root files/dpkg.cfg.d/delete-sysvinit-folders-hook  ${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/
install -m 644 -g root -o root files/dpkg.cfg.d/delete-upstart-folder-hook  ${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/

# Delete upstart and sysvinit folders
rm -rf ${ROOTFS_DIR}/etc/init
rm -rf ${ROOTFS_DIR}/etc/init.d ${ROOTFS_DIR}/etc/rc0.d ${ROOTFS_DIR}/etc/rc1.d ${ROOTFS_DIR}/etc/rc2.d ${ROOTFS_DIR}/etc/rc3.d ${ROOTFS_DIR}/etc/rc4.d ${ROOTFS_DIR}/etc/rc5.d ${ROOTFS_DIR}/etc/rc6.d ${ROOTFS_DIR}/etc/rcS.d
rm -rf ${ROOTFS_DIR}/etc/insserv.conf.d
