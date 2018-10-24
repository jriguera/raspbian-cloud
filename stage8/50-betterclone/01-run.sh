#!/bin/bash -e

VERSION="1.44"
ARCH="arm"

# Install and enable Prometheus node_exporter
#on_chroot <<EOF
#curl -sSL https://github.com/ncw/rclone/releases/download/v${VERSION}/rclone-v${VERSION}-linux-${ARCH}.zip -o /tmp/rclone.zip
#unzip -d /tmp /tmp/rclone.zip
#mkdir -p /usr/local/bin/
#mv /tmp/rclone-v${VERSION}-linux-${ARCH}/rclone /usr/local/bin/
#mkdir -p /usr/local/man/man1/
#mv /tmp/rclone-v${VERSION}-linux-${ARCH}/rclone.1 /usr/local/man/man1/
#rm -rf /tmp/rclone.zip /tmp/rclone-v${VERSION}-linux-${ARCH}
#EOF

