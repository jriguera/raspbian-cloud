#!/bin/bash -e

# Delete journal
#on_chroot << EOF
#journalctl --rotate
#journalctl --vacuum-time=1s
#EOF

rm -rf ${ROOTFS_DIR}/var/log/journal/*