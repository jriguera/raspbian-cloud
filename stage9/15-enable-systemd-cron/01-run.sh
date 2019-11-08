#!/bin/bash -e

# Disable cron daemon
on_chroot << EOF
systemctl disable cron
apt-get -y purge cron
EOF

