#!/bin/bash -e

# https://www.enricozini.org/blog/2019/himblick/cleanup-raspbian/

on_chroot << EOF
systemctl disable regenerate_ssh_host_keys.service
systemctl mask regenerate_ssh_host_keys.service

systemctl disable apply_noobs_os_config.service
systemctl mask apply_noobs_os_config.service

systemctl disable sshswitch.service
systemctl mask sshswitch.service

systemctl disable wifi-country.service
systemctl mask wifi-country.service

apt-mark hold raspberrypi-sys-mods
EOF

rm -f "${ROOTFS_DIR}/etc/profile.d/wifi-country.sh"
rm -f "${ROOTFS_DIR}/etc/sudoers.d/010_pi-nopasswd"

