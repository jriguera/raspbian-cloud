#!/bin/bash -e

LABEL=volume-data
VOLUME="/media/${LABEL}"

DATA_SUBVOL="${VOLUME}/data"
DATA_MOUNTPOINT=/data
DATA_LABEL=data

###

# remove trailing slash
DATA_SUBVOL=${BACKUP_SUBVOL%%+(/)}
#VOLUME=${VOLUME%%+(/)}

# start slash
DATA_SUBVOL=${BACKUP_SUBVOL##+(/)}
#VOLUME_SYSTEMD=$(systemd-escape --path ${VOLUME##+(/)})

# Copy binary
install -m 755 -g root -o root rpi-btrfs/bin/* ${ROOTFS_DIR}/bin
install -m 755 -g root -o root rpi-btrfs/requirements.txt ${ROOTFS_DIR}/tmp

## Install requiremets
on_chroot <<EOF
pip3 install -r /tmp/requirements.txt
rm -f /tmp/requirements.txt
EOF

# Monit
install -m 775 -g root -o root -d ${ROOTFS_DIR}/etc/monit/conf.d
cat <<EOF >"${ROOTFS_DIR}/etc/monit/conf.d/${LABEL}fs"
## Check filesystem permissions, uid, gid, space and inode usage. Other services,
## such as databases, may depend on this resource and an automatically graceful
## stop may be cascaded to them before the filesystem will become full and data
## lost.
#
check filesystem ${LABEL}fs with path ${VOLUME}
    if space usage > 90% for 5 times within 15 cycles then alert
    if inode usage > 95% then alert
    if changed fsflags then alert
    group system
    group ${LABEL}fs

check program ${LABEL}fs-status with path "/bin/btrfs-check -m ${VOLUME}"
    if status != 0 then alert
    if status != 0 for 5 cycles then unmonitor
    depends on ${LABEL}fs
    group system
    group ${LABEL}fs
EOF

# Systemd
install -m 644 -g root -o root rpi-btrfs/systemd/*.service "${ROOTFS_DIR}/lib/systemd/system/${LABEL}@.service"

# udev rules
install -m 644 -g root -o root rpi-btrfs/udev/* "${ROOTFS_DIR}/etc/udev/rules.d/

# Default config
cat <<EOF >"${ROOTFS_DIR}/etc/default/${LABEL}"
# ${LABEL}@.service configuration
LABEL="${LABEL}"
SUBVOLS="--subvol ${DATA_LABEL}:${DATA_MOUNTPOINT}"
DATA_LABEL="${DATA_LABEL}"

# Only for subvols
MOUNT_OPTS="defaults,noatime,nodiratime"
EOF

# mkdir volume
mkdir -p ${ROOTFS_DIR}${VOLUME}


# Backups
on_chroot <<EOF
# Enable devices

# Enable backups with betterclone
systemctl enable betterclone-backup.target
systemctl enable betterclone-restore.target
systemctl enable "betterclone-restore@`systemd-escape --path ${DATA_SUBVOL}`.service"
systemctl enable "betterclone-backup@`systemd-escape --path ${DATA_SUBVOL}`.timer"
EOF
