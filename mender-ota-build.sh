#!/bin/sh
set -e

IMAGE_NAME=mender-convert
MENDER_CONVERT_DIR="$(pwd)"

mkdir -p output

# Read configuration
. config

docker run --mount type=bind,source="$MENDER_CONVERT_DIR,target=/mender-convert"
           --privileged=true                                       \
           --cap-add=SYS_MODULE                                    \
           -v /dev:/dev                                            \
           -v /lib/modules:/lib/modules:ro                         \
           $IMAGE_NAME                                             \
              from-raw-disk-image                                  \
              --raw-disk-image $RAW_DISK_IMAGE                     \
              --mender-disk-image $MENDER_DISK_IMAGE               \
              --device-type $DEVICE_TYPE                           \
              --artifact-name $ARTIFACT_NAME                       \
              --bootloader-toolchain arm-buildroot-linux-gnueabihf \
              --server-url $MENDER_SERVER                          \
              --tenant-token $TENANT_TOKEN
