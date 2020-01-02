#!/bin/bash -e

VERSION="0.10-beta.1"
ARCH="arm"

# Install lazydocker
on_chroot <<EOF
curl -sSL https://github.com/moncho/dry/releases/download/v${VERSION}/dry-linux-${ARCH} -o /usr/sbin/dry
chown root.root /usr/sbin/dry
chmod a+x /usr/sbin/dry
EOF

