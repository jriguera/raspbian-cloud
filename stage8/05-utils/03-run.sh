#!/bin/bash -e

VERSION="3.3.0"
ARCH="arm"

# Install lazydocker
on_chroot <<EOF
curl -sSL https://github.com/mikefarah/yq/releases/download/${VERSION}/yq_linux_${ARCH} -o /usr/local/bin/yq
chown root.root /usr/local/bin/yq
chmod a+x /usr/local/bin/yq
EOF

