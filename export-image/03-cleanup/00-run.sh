#!/bin/bash -e

on_chroot << EOF
apt-get autoremove --purge -y
apt-get clean -y
EOF
