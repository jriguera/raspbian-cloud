#!/bin/bash -e

VERSION="0.17.0"
ARCH="armv6"

# Install and enable Prometheus node_exporter
on_chroot <<EOF
curl -sSL https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-${ARCH}.tar.gz -o /tmp/node_exporter.tar.gz
tar -xvf /tmp/node_exporter.tar.gz -C /usr/sbin/ --strip-components=1 --wildcards --no-anchored node_exporter
rm -f /tmp/node_exporter.tar.gz
# System user and group
addgroup --system node_exporter
adduser --system --home /var/lib/misc --shell /bin/false --no-create-home  --gecos "Prometheus Node Exporter" --ingroup node_exporter --disabled-password --disabled-login  node_exporter
EOF

install -m 644 -g root -o root files/default ${ROOTFS_DIR}/etc/default/node_exporter

# Systemd service
install -m 644 -g root -o root files/systemd/node_exporter.service ${ROOTFS_DIR}/lib/systemd/system

on_chroot <<EOF
systemctl enable node_exporter
EOF

# Monit
install -m 775 -g root -o root -d ${ROOTFS_DIR}/etc/monit/conf-available/
install -m 644 -g root -o root files/monit/* ${ROOTFS_DIR}/etc/monit/conf-available/
on_chroot << EOF
mkdir -p /etc/monit/conf-enabled
cd /etc/monit/conf-enabled
ln -sf ../conf-available/node_exporter
EOF

