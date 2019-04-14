#!/bin/bash -e

COMPOSE_CONFIG_FOLDER=/etc/docker-compose

# remove trailing slash
COMPOSE_CONFIG_FOLDER=${COMPOSE_CONFIG_FOLDER%%+(/)}
# start slash
COMPOSE_CONFIG_FOLDER=${COMPOSE_CONFIG_FOLDER##+(/)}

## Install docker-compose
install -m 755 -g root -o root docker-rpi-dockercompose/bin/system-docker-compose ${ROOTFS_DIR}/usr/bin/

# docker-compose services
install -m 644 -g root -o root docker-rpi-dockercompose/systemd/docker-compose.target ${ROOTFS_DIR}/lib/systemd/system
install -m 644 -g root -o root docker-rpi-dockercompose/systemd/docker-compose@.service ${ROOTFS_DIR}/lib/systemd/system
install -m 644 -g root -o root docker-rpi-dockercompose/systemd/docker-compose-refresh@.service ${ROOTFS_DIR}/lib/systemd/system
install -m 644 -g root -o root docker-rpi-dockercompose/systemd/docker-compose-refresh.service ${ROOTFS_DIR}/lib/systemd/system
install -m 644 -g root -o root docker-rpi-dockercompose/systemd/docker-compose-refresh.timer ${ROOTFS_DIR}/lib/systemd/system

# Install docker dompose services
on_chroot <<EOF
systemctl enable docker-compose.target
# Enable docker-compose boot service
systemctl enable "docker-compose@`systemd-escape --path ${COMPOSE_CONFIG_FOLDER}`.service"
systemctl enable "docker-compose-refresh@`systemd-escape --path ${COMPOSE_CONFIG_FOLDER}`.service"
EOF

# Copy default configuration
mkdir -p ${ROOTFS_DIR}/${COMPOSE_CONFIG_FOLDER}
install -m 644 -g root -o root docker-rpi-dockercompose/example/docker-compose.yml ${ROOTFS_DIR}/${COMPOSE_CONFIG_FOLDER}/
install -m 644 -g root -o root docker-rpi-dockercompose/example/config.env  ${ROOTFS_DIR}/${COMPOSE_CONFIG_FOLDER}/
