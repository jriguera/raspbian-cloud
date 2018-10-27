#!/bin/bash -e

on_chroot << EOF
apt-get -y autoremove
apt-get -y clean
EOF

