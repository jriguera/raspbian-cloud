#!/bin/bash -e

# Config
install -m 644 -g root -o root files/smtpd.conf ${ROOTFS_DIR}/etc/
install -m 644 -g root -o root files/default ${ROOTFS_DIR}/etc/default/smtp

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

# Monit
install -m 775 -g root -o root -d ${ROOTFS_DIR}/etc/monit/conf-available/
install -m 644 -g root -o root files/monit/* ${ROOTFS_DIR}/etc/monit/conf-available/
on_chroot << EOF
mkdir -p /etc/monit/conf-enabled
cd /etc/monit/conf-enabled
ln -sf ../conf-available/opensmtpd
EOF

