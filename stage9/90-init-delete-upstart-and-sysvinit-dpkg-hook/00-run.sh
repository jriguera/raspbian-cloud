#!/bin/bash -e

# dpkg hooks to delete unneeded folders sysvinit and upstart, because of the fact of using systemd as default init 
install -m 644 -g root -o root files/dpkg.cfg.d/delete-sysvinit-folders-hook  ${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/
install -m 644 -g root -o root files/dpkg.cfg.d/delete-upstart-folder-hook  ${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/
