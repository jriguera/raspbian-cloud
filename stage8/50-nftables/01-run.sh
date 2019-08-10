#!/bin/bash -e

on_chroot <<EOF
# Disable service
systemctl disable nftables.service
EOF
