#!/bin/bash -e

# Remove packages
on_chroot << EOF
apt-get purge -y xdg-user-dirs triggerhappy
EOF

