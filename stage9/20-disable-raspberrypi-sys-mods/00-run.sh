#!/bin/bash -e

# This functionality is done by cloud-init or automatically enabled

on_chroot << EOF
systemctl disable regenerate_ssh_host_keys.service
systemctl disable apply_noobs_os_config.service
systemctl disable rpi-display-backlight.service
systemctl disable sshswitch.service
systemctl disable wifi-country.service
apt-mark hold raspberrypi-sys-mods
EOF

rm -f "${ROOTFS_DIR}/etc/profile.d/wifi-country.sh"
rm -f "${ROOTFS_DIR}/etc/sudoers.d/010_pi-nopasswd"
