#!/bin/bash -e

VERSION="0.15.2"

# Install and enable Prometheus node_exporter
on_chroot <<EOF
ARCH=$(uname -m | cut -c1-5)
curl -SL https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-${ARCH}.tar.gz -o /tmp/node_exporter.tar.gz
tar -xvf /tmp/node_exporter.tar.gz -C /usr/local/sbin/ --strip-components=1 --wildcards --no-anchored node_exporter
rm -f /tmp/node_exporter.tar.gz
# System user and group
addgroup --system node_exporter
adduser --system --home /var/lib/misc --shell /bin/false --no-create-home  --gecos "Prometheus Node Exporter" --ingroup node_exporter --disabled-password --disabled-login  node_exporter
EOF

install -m 644 -g root -o root files/default ${ROOTFS_DIR}/etc/default/node_exporter

# Systemd service
install -m 644 -g root -o root files/systemd/node_exporter.service ${ROOTFS_DIR}/etc/systemd/system

on_chroot <<EOF
systemctl enable node-exporter.service
EOF
