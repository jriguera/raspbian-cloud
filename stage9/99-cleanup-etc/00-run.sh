#!/bin/bash -e

rm -rf ${ROOTFS_DIR}/etc/staff-group-for-usr-local
rm -rf ${ROOTFS_DIR}/etc/X11
rm -rf ${ROOTFS_DIR}/etc/anacrontab

rm -rf ${ROOTFS_DIR}/etc/binfmt.d
rm -rf ${ROOTFS_DIR}/etc/apache2
rm -rf ${ROOTFS_DIR}/etc/gdb
rm -rf ${ROOTFS_DIR}/etc/lighttpd
rm -rf ${ROOTFS_DIR}/etc/python2.7
