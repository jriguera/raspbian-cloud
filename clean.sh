#!/bin/bash

umount work/*-RaspbianCloud/stage0/rootfs/sys
umount work/*-RaspbianCloud/stage0/rootfs/dev/pts
umount work/*-RaspbianCloud/stage0/rootfs/dev
umount work/*-RaspbianCloud/stage0/rootfs/proc

rm -rf work/*-RaspbianCloud

