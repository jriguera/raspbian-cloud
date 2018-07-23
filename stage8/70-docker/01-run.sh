#!/bin/bash -e

# Install and enable docker
on_chroot <<EOF
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
install -m 644 -g root -o root files/systemd/docker-cleanup.timer ${ROOTFS_DIR}/etc/systemd/system
install -m 644 -g root -o root files/systemd/docker-cleanup.service ${ROOTFS_DIR}/etc/systemd/system
on_chroot <<EOF
systemctl enable docker-cleanup.service
EOF


## Install docker-compose
on_chroot <<EOF
pip3 install docker-compose
# or (old version)
# apt-get install -y docker-compose
EOF

# docker-compose services
install -m 644 -g root -o root files/systemd/docker-compose.target ${ROOTFS_DIR}/etc/systemd/system
install -m 644 -g root -o root files/systemd/docker-compose@.service ${ROOTFS_DIR}/etc/systemd/system
install -m 644 -g root -o root files/systemd/docker-compose-refresh@.service ${ROOTFS_DIR}/etc/systemd/system
install -m 644 -g root -o root files/systemd/docker-compose-refresh.service ${ROOTFS_DIR}/etc/systemd/system
install -m 644 -g root -o root files/systemd/docker-compose-refresh.timer ${ROOTFS_DIR}/etc/systemd/system
# /boot folder services
install -m 644 -g root -o root files/systemd/docker-compose@.service ${ROOTFS_DIR}/etc/systemd/system/docker-compose@boot-docker-compose.service
install -m 644 -g root -o root files/systemd/docker-compose-refresh@.service ${ROOTFS_DIR}/etc/systemd/system/docker-compose-refresh@boot-docker-compose.service

# Install docker dompose services
on_chroot <<EOF
mkdir -p /boot/docker/compose
systemctl enable docker-compose.target
# Enable docker-compose boot service
systemctl enable docker-compose@boot-docker-compose.service
EOF

# Copy default configuration
mkdir -p ${ROOTFS_DIR}/boot/docker/compose
install -m 644 -g root -o root files/boot/docker-compose.yml ${ROOTFS_DIR}/boot/docker/compose/
