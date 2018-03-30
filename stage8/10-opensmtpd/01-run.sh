#!/bin/bash -e

# Config
install -m 644 -g root -o root files/mailname ${ROOTFS_DIR}/etc/
install -m 644 -g root -o root files/smtpd.conf ${ROOTFS_DIR}/etc/

# Create config folder
on_chroot << EOF
mkdir -p /etc/mail
ln -s ../aliases /etc/mail/aliases
touch /etc/mail/smtpd.conf.local
chown -R root:opensmtpd /etc/mail
EOF

# Add user to aliases
echo "root: pi"  >> ${ROOTFS_DIR}/etc/aliases

# Systemd service
install -m 644 -g root -o root files/systemd/opensmtpd.service ${ROOTFS_DIR}/etc/systemd/system
on_chroot << EOF
systemctl enable opensmtpd
EOF
