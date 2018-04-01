#!/bin/bash -e

# Uninstall
on_chroot << EOF
apt-get -y purge rsyslog
rm -rf /etc/rsyslog.conf /etc/rsyslog.d/
EOF

