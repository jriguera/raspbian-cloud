#!/bin/bash -e

VERSION="1.20.12"
ARCH="ARM_32-bitv6"

# Install lazydocker
on_chroot <<EOF
curl -sSL https://github.com/amir20/dozzle/releases/download/v${VERSION}/dozzle_${VERSION}_Linux_${ARCH}.tar.gz -o /tmp/dozzle.tar.gz
tar -xvf /tmp/dozzle.tar.gz -C /usr/sbin/ --wildcards --no-anchored dozzle
chown root.root /usr/sbin/dozzle
chmod a+x /usr/sbin/dozzle
rm -f /tmp/dozzle.tar.gz
EOF

