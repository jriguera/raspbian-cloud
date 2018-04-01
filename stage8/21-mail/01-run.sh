#!/bin/bash -e

# Add user to aliases
grep -q '^root:'  ${ROOTFS_DIR}/etc/aliases || echo 'root:	pi' >> ${ROOTFS_DIR}/etc/aliases
