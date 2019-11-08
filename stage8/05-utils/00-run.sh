#!/bin/bash -e

VERSION="0.7.4"
ARCH="armv6"

# Install lazydocker
on_chroot <<EOF
curl -sSL  https://github.com/jesseduffield/lazydocker/releases/download/v${VERSION}/lazydocker_${VERSION}_Linux_${ARCH}.tar.gz -o /tmp/lazydocker.tar.gz
tar -xvf /tmp/lazydocker.tar.gz -C /usr/sbin/ --wildcards --no-anchored lazydocker
chown root.root /usr/sbin/lazydocker
chmod a+x /usr/sbin/lazydocker
rm -f /tmp/lazydocker.tar.gz
EOF

