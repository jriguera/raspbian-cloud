#!/bin/bash -e

# https://www.enricozini.org/blog/2019/himblick/cleanup-raspbian/

on_chroot << EOF
apt-get -y purge raspi-config
EOF
