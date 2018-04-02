#!/bin/bash -e

on_chroot << EOF
apt-get -y purge avahi-daemon
rm -rf /etc/avahi
EOF
