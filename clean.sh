#!/bin/bash

umount work/*-RaspbianCloud/stage*/rootfs/sys
umount work/*-RaspbianCloud/stage*/rootfs/dev/pts
umount work/*-RaspbianCloud/stage*/rootfs/dev
umount work/*-RaspbianCloud/stage*/rootfs/proc

rm -rf work/*-RaspbianCloud

