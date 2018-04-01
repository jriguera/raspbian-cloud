#!/bin/bash -e

# Config
install -m 644 -g root -o root files/smtpd.conf ${ROOTFS_DIR}/etc/

# Create config folder
on_chroot << EOF
mkdir -p /etc/mail
ln -s ../aliases /etc/mail/aliases
touch /etc/mail/smtpd.conf.local
chown -R root:opensmtpd /etc/mail
EOF

# Systemd service
on_chroot << EOF
systemctl enable opensmtpd
EOF
