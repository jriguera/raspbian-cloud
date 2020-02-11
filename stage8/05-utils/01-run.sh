#!/bin/bash -e

VERSION="3.0.0"
ARCH="arm6"

# Install gotop
on_chroot <<EOF
curl -sSL https://github.com/cjbassi/gotop/releases/download/${VERSION}/gotop_${VERSION}_linux_${ARCH}.tgz -o /tmp/gotop.tar.gz
tar -xvf /tmp/gotop.tar.gz -C /usr/local/bin/ --wildcards --no-anchored gotop
chown root.root /usr/local/bin/gotop
chmod a+x /usr/local/bin/gotop
rm -f /tmp/gotop.tar.gz
EOF

