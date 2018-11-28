#!/bin/bash -e

LABEL=volume-data
VOLUME=/media/volume-data

DATA_SUBVOL=/media/volume-data/data
DATA_MOUNTPOINT=/data
DATA_LABEL=data

###

# remove trailing slash
DATA_SUBVOL=${BACKUP_SUBVOL%%+(/)}
VOLUME=${VOLUME%%+(/)}

# start slash
DATA_SUBVOL=${BACKUP_SUBVOL##+(/)}
VOLUME_SYSTEMD=$(systemd-escape --path ${VOLUME##+(/)})

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
cat <<EOF >"${ROOTFS_DIR}/etc/monit/conf.d/${LABEL}"
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

check program ${LABEL}-raid with path "/bin/btrfs-check -m ${VOLUME}"
    if status != 0 then alert
    if status != 0 for 5 cycles then exec "/bin/btrfs-balance-raid ${VOLUME} ${LABEL}"
    if status != 0 for 5 cycles then unmonitor
    depends on ${LABEL}fs
    group system
EOF

# Systemd
install -m 644 -g root -o root "rpi-btrfs/systemd/media-volume\x2ddata@.service" "${ROOTFS_DIR}/lib/systemd/system/${VOLUME_SYSTEMD}@.service"

# Default config
cat <<EOF >"${ROOTFS_DIR}/etc/default/${VOLUME_SYSTEMD}"
# media-volume-data@.service configuration
LABEL="${LABEL}"
SUBVOLS="--subvol ${DATA_LABEL}:${DATA_MOUNTPOINT}"
DATA_LABEL="${DATA_LABEL}"
# Only for subvols
MOUNT_OPTS="defaults,noatime,nodiratime"
EOF


# fstab for automatic setup
mkdir -p ${ROOTFS_DIR}${VOLUME}
echo >> ${ROOTFS_DIR}/etc/fstab
echo "LABEL=${LABEL}	${VOLUME}	btrfs	defaults,noatime,nodiratime,x-systemd.after=/dev/sda,x-systemd.after=/dev/sdb,x-systemd.after=${VOLUME_SYSTEMD}@dev-sda.service,x-systemd.after=${VOLUME_SYSTEMD}@dev-sdb.service		0 	2" >> ${ROOTFS_DIR}/etc/fstab


# Backups
on_chroot <<EOF
# Enable backups with betterclone
systemctl enable betterclone-backup.target
systemctl enable betterclone-restore.target
systemctl enable "betterclone-restore@`systemd-escape --path ${DATA_SUBVOL}`.service"
systemctl enable "betterclone-backup@`systemd-escape --path ${DATA_SUBVOL}`.timer"
EOF
