#!/bin/bash -e

VERSION="0.10-beta.1"
ARCH="arm"

# Install dry
on_chroot <<EOF
curl -sSL https://github.com/moncho/dry/releases/download/v${VERSION}/dry-linux-${ARCH} -o /usr/local/bin/dry
chown root.root /usr/local/bin/dry
chmod a+x /usr/local/bin/dry
EOF

