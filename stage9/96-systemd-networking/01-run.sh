#!/bin/bash -e

# https://raspberrypi.stackexchange.com/questions/78787/howto-migrate-from-networking-to-systemd-networkd-with-dynamic-failover/78788#78788

# Install systemd network files
install -m 644 -g root -o root files/systemd/* ${ROOTFS_DIR}/etc/systemd/network/

on_chroot <<EOF
# Disable old network services
systemctl mask networking.service
systemctl mask dhcpcd.service

# Enable systemd-networkd
systemctl enable systemd-networkd.service
EOF


# wpa_supplicant service
on_chroot <<EOF
# Disable default wpa_supplicant service
systemctl disable wpa_supplicant.service
systemctl enable wpa_supplicant@wlan0.service

cp /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

# Uninstall services
apt-get -y purge ifupdown
apt-get -y purge dhcpcd5
apt-get -y purge isc-dhcp-client isc-dhcp-common

apt-get -y autoremove
# Remove old networking files
rm -rf /etc/network /etc/dhcp* /etc/ifplugd /etc/NetworkManager /etc/ppp
rm -f /etc/dhcpcd.exit-hook /etc/resolv.dhcp.conf
EOF
