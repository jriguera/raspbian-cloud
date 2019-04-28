#!/bin/bash -e

install -m 644 -g root -o root files/cloud.cfg ${ROOTFS_DIR}/etc/cloud/
install -m 644 -g root -o root files/cloud.cfg.d/* ${ROOTFS_DIR}/etc/cloud/cloud.cfg.d/
install -m 644 -g root -o root files/templates/sources.list.debian.tmpl ${ROOTFS_DIR}/etc/cloud/templates/

install -m 644 -g root -o root files/boot/* ${ROOTFS_DIR}/boot/

mkdir -p ${ROOTFS_DIR}/var/lib/cloud/scripts/per-once
install -m 755 -g root -o root files/scripts/vendor/00-resize-root-fs.sh ${ROOTFS_DIR}/var/lib/cloud/scripts/per-once

install -m 644 -g root -o root files/bugfix/cc_disk_setup.py ${ROOTFS_DIR}/usr/lib/python3/dist-packages/cloudinit/config/

# Redirect logs to tty in systemd
#systemd_tty() {
#    local tty=$1
#cat <<EOF
#[Service]
#StandardOutput=tty
#TTYPath=/dev/$tty
#TTYReset=yes
#TTYVHangup=yes
#TTYVTDisallocate=no
#EOF
#}
#mkdir -p ${ROOTFS_DIR}/etc/systemd/system/cloud-config.service.d
#mkdir -p ${ROOTFS_DIR}/etc/systemd/system/cloud-final.service.d
#mkdir -p ${ROOTFS_DIR}/etc/systemd/system/cloud-init-local.service.d
#mkdir -p ${ROOTFS_DIR}/etc/systemd/system/cloud-init.service.d
#TTY=tty4
#systemd_tty $TTY > ${ROOTFS_DIR}/etc/systemd/system/cloud-config.service.d/tty.conf
#systemd_tty $TTY > ${ROOTFS_DIR}/etc/systemd/system/cloud-final.service.d/tty.conf
#systemd_tty $TTY > ${ROOTFS_DIR}/etc/systemd/system/cloud-init-local.service.d/tty.conf
#systemd_tty $TTY > ${ROOTFS_DIR}/etc/systemd/system/cloud-init.service.d/tty.conf
