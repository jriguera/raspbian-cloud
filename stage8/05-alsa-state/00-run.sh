#!/bin/bash -e

on_chroot << EOF
touch /var/lib/alsa/asound.state
EOF
