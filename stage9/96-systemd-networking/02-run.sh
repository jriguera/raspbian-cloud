#!/bin/bash -e

# Dnsmasq will point to systemd resolv instead of /run/systemd/resolve/resolv.conf
# and /etc/resolv.conf to /run/systemd/resolve/stub-resolv.conf

install -m 644 -g root -o root files/dnsmasq/dns-servers.conf ${ROOTFS_DIR}/etc/dnsmasq.d/
install -m 644 -g root -o root files/resolved.conf ${ROOTFS_DIR}/etc/systemd/

on_chroot << EOF
systemctl enable systemd-resolved.service

# Uninstall services
apt-get -y purge openresolv

# Make a link to the systemd resolver
rm -rf /etc/resolvconf /etc/resolv.conf.head
mkdir -p /run/systemd/resolve
mv /etc/resolv.conf /run/systemd/resolve/stub-resolv.conf
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
EOF
