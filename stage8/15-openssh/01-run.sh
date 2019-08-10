#!/bin/bash -e

# Config
install -m 644 -g root -o root files/default ${ROOTFS_DIR}/etc/default/ssh

# systemctl override
install -m 775 -g root -o root -d ${ROOTFS_DIR}/etc/systemd/system/ssh.service.d
install -m 644 -g root -o root files/systemd/override.conf ${ROOTFS_DIR}/etc/systemd/system/ssh.service.d

# Enable ssh
on_chroot << EOF
# Tweak sshd to prevent DNS resolution (speed up logins)
sed -i -e 's/^#UseDNS.*/UseDNS no/' /etc/ssh/sshd_config
sed -i -e 's/^#TCPKeepAlive.*/TCPKeepAlive yes/' /etc/ssh/sshd_config
sed -i -e 's/^#Compression.*/Compression delayed/' /etc/ssh/sshd_config

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

