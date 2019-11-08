#!/bin/bash -e

VERSION='5:18.09.8~3-0~debian-buster'
VERSION='5:19.03.4~3-0~raspbian-buster'

# Install and enable docker
on_chroot <<EOF
# 1. Official method
#curl -sSL https://get.docker.com/ | sh
#echo "deb [arch=armhf] https://download.docker.com/linux/raspbian stretch stable" >  /etc/apt/sources.list.d/docker.list
# 2. Alternative
curl -fsSL "https://download.docker.com/linux/raspbian/gpg" | apt-key add -qq - >/dev/null
echo "deb [arch=armhf] https://download.docker.com/linux/raspbian buster stable" > /etc/apt/sources.list.d/docker-ce.list
echo "deb-src https://download.docker.com/linux/raspbian buster stable" >> /etc/apt/sources.list.d/docker-ce.list
apt-get update -qq
apt-get install --no-install-recommends -y docker-ce-cli="${VERSION}"
apt-get install --no-install-recommends -y docker-ce="${VERSION}"
apt-mark hold docker-ce docker-ce-cli
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
