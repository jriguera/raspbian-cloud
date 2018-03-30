#!/bin/bash -e

rm -rf ${ROOTFS_DIR}/etc/staff-group-for-usr-local
rm -rf ${ROOTFS_DIR}/etc/NetworkManager
rm -rf ${ROOTFS_DIR}/etc/X11
rm -rf ${ROOTFS_DIR}/etc/init
rm -rf ${ROOTFS_DIR}/etc/init.d ${ROOTFS_DIR}/etc/rc0.d ${ROOTFS_DIR}/etc/rc1.d ${ROOTFS_DIR}/etc/rc2.d ${ROOTFS_DIR}/etc/rc3.d ${ROOTFS_DIR}/etc/rc4.d ${ROOTFS_DIR}/etc/rc5.d ${ROOTFS_DIR}/etc/rc6.d ${ROOTFS_DIR}/etc/rcS.d
rm -rf ${ROOTFS_DIR}/etc/ppp
