#!/bin/bash -e

# Install overlays for tft GPIO displays
install -m 755 -g root -o root  LCD-show/usr/tft*-overlay.dtb ${ROOTFS_DIR}/boot/overlays/
cp -a ${ROOTFS_DIR}/boot/overlays/tft9341-overlay.dtb  ${ROOTFS_DIR}/boot/overlays/tft9341.dtbo
cp -a ${ROOTFS_DIR}/boot/overlays/tft35a-overlay.dtb  ${ROOTFS_DIR}/boot/overlays/tft35a.dtbo

# Install overlays for HDMI displays
install -m 755 -g root -o root  LCD-show/usr/mhs*-overlay.dtb ${ROOTFS_DIR}/boot/overlays/
cp -a ${ROOTFS_DIR}/boot/overlays/mhs24-overlay.dtb  ${ROOTFS_DIR}/boot/overlays/mhs24.dtbo
cp -a ${ROOTFS_DIR}/boot/overlays/mhs32-overlay.dtb  ${ROOTFS_DIR}/boot/overlays/mhs32.dtbo
cp -a ${ROOTFS_DIR}/boot/overlays/mhs35-overlay.dtb  ${ROOTFS_DIR}/boot/overlays/mhs35.dtbo
cp -a ${ROOTFS_DIR}/boot/overlays/mhs35b-overlay.dtb  ${ROOTFS_DIR}/boot/overlays/mhs35b.dtbo
cp -a ${ROOTFS_DIR}/boot/overlays/mhs395-overlay.dtb  ${ROOTFS_DIR}/boot/overlays/mhs395.dtbo

