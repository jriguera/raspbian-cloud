#!/bin/bash -e

# Install and enable docker
on_chroot <<EOF
export VERSION="18.06.3"
curl -sSL https://get.docker.com/ | sh
usermod -aG docker pi
EOF

install -m 644 -g root -o root files/default ${ROOTFS_DIR}/etc/default/docker
mkdir -p ${ROOTFS_DIR}/etc/docker
install -m 644 -g root -o root files/daemon.json ${ROOTFS_DIR}/etc/docker
mkdir -p ${ROOTFS_DIR}/etc/systemd/system/docker.service.d
install -m 644 -g root -o root files/systemd/docker.conf ${ROOTFS_DIR}/etc/systemd/system/docker.service.d
on_chroot <<EOF
systemctl enable docker
EOF

# Docker cleanup
install -m 644 -g root -o root files/systemd/docker-cleanup.timer ${ROOTFS_DIR}/lib/systemd/system
install -m 644 -g root -o root files/systemd/docker-cleanup.service ${ROOTFS_DIR}/lib/systemd/system
on_chroot <<EOF
systemctl enable docker-cleanup.service
EOF

# Monit
install -m 775 -g root -o root -d ${ROOTFS_DIR}/etc/monit/conf-available/
install -m 644 -g root -o root files/monit/* ${ROOTFS_DIR}/etc/monit/conf-available/
on_chroot << EOF
mkdir -p /etc/monit/conf-enabled
cd /etc/monit/conf-enabled
ln -sf ../conf-available/docker
EOF
