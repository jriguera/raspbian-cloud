#!/bin/bash -e

# Enable ssh
on_chroot << EOF
systemctl enable ssh
EOF

# Publish ssh in avahi
cp ${ROOTFS_DIR}/usr/share/doc/avahi-daemon/examples/ssh.service  ${ROOTFS_DIR}/etc/avahi/services/

# Monit
install -m 775 -g root -o root -d ${ROOTFS_DIR}/etc/monit/conf-available/
install -m 644 -g root -o root files/monit/* ${ROOTFS_DIR}/etc/monit/conf-available/
on_chroot << EOF
mkdir -p /etc/monit/conf-enabled
cd /etc/monit/conf-enabled
ln -sf ../conf-available/openssh-server
EOF

