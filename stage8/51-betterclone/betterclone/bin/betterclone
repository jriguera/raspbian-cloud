#!/usr/bin/env bash
[ -z "$DEBUG" ] || set -x
#set -u

export LC_ALL=C

PROGRAM=${PROGRAM:-$(basename "${BASH_SOURCE[0]}")}
PROGRAM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROGRAM_OPTS=$@
if [ -z "${PREFIX}" ]
then
  PROGRAM_LOGDIR="${PROGRAM_LOGDIR:-/var/log/betterclone}"
  PROGRAM_CFGD="${PROGRAM_CFGD:-/etc/betterclone}"
else
  PROGRAM_LOGDIR="${PROGRAM_LOGDIR:-${PREFIX}/log}"
  PROGRAM_CFGD="${PROGRAM_CFGD:-${PREFIX}/etc}"
fi
PROGRAM_LOG="${PROGRAM_LOG:-$PROGRAM_LOGDIR/betterclone-$$.log}"
source "${PROGRAM_CFGD}/config.env"

BACKUP_CFG="${BACKUP_CFG:-.backup.betterclone}"
RESTORE_CFG="${RESTORE_CFG:-.restore.betterclone}"
BACKUP_LOCK="${BACKUP_LOCK:-.betterclone.lock}"
BACKUP_TOOL_DEFAULT=${RCLONE}
BACKUP_TOOL_DEFAULT_CFG="${PROGRAM_CFGD}/rclone.conf"

# DO NOT CHANGE!!!!! Policy is based on this format, it will not work with
# a different format
POLICY_DATE=$(date +'%y.%m.%d-%w-%s')

# Exit codes >= 1000 coming from this script

# https://btrfs.wiki.kernel.org/index.php/UseCases
# https://wiki.lexruee.ch/btrfs/

################################################################################

usage() {
    cat <<EOF
Usage:
    $PROGRAM [-h] {help|init|backup|recover} <mountpoint-folder> [options]

This program creates snapshots based on filesystem tools and performs backups
of those snapshots if needed. It manages the list of (old) snapshots and
the list of backups based on policies defined by some parameters in the
configuration file placed in "<mountpoint-folder>/$BACKUP_CFG".
The script does not allow to run more than one instance on each
<mountpoint-folder> by creating a lock file "<mountpoint-folder>/$BACKUP_LOCK"
with the current pid.

Options:
    -h      Shows usage help

Commands
    init    Initialize default backup settings for the provided mountpoint
    help    Show this help message
    backup  Perform a backup on the mountpoint.
            Options: force, nohooks, skip-hooks-snapshot, skip-hooks-backup
    restore Recover the data from a backup or a snapshot.
            Options: nokeep, nokooks

Regarding snapshots, currently only Btrfs filesystem is supported, but it is
possible to extend the functionality to other filesystems by writing some
small bash functions.

Regarding backups, currently only Rclone is supported. Note that a backups is a
external copy of a snapshot using Rclone, there is no concept of incremental
backups, so be aware all copies are "full" backups.

Because of the usage of filesystem tools, this program needs to run as root.

(c) Jose Riguera Lopez 2018 <jriguera@gmail.com>

EOF
}


log() {
    local message=${1}
    local timestamp=$(date +%y:%m:%d-%H:%M:%S)
    echo "${timestamp} :: ${message}" >> "${PROGRAM_LOG}"
}


echo_log() {
    local message="${1}"
    local timestamp=$(date +%y:%m:%d-%H:%M:%S)
    echo "${timestamp} :: ${message}" | tee -a "${PROGRAM_LOG}"
}


# Print a message without \n at the end
error_log() {
    local message="${1}"
    local rc="${2}"
    local timestamp=$(date +%y:%m:%d-%H:%M:%S)
    [ -z "${rc}" ] && rc=1
    echo "${timestamp} :: RC=${rc} ERROR: ${message}" | tee -a "${PROGRAM_LOG}"
}


pipe_log() {
    awk '{ print "···················> "$0}' | tee -a "${PROGRAM_LOG}"
}


# Print a message and exit with error
die() {
    { cat <<< "$@" 1>&2; }
    exit 1
}


# Gets the FS type of a mountpoint. Returns 1 if it is not a mountpoint
get_mountpoint_fs() {
    local mountpoint="${1}"

    local fs
    local rvalue

    fs=$(stat -f --format=%T "${mountpoint}")
    rvalue=$?
    if [ -z "${fs}" ] || [ "${rvalue}" -ne "0" ]
    then
        return 1
    fi
    echo "${fs}"
    return 0
}


# Safely read a variable from a config file. Returns 0 if variable
# is defined, 1 if not. It always returns via stdout the default value.
read_cfg_param() {
    local cfg="${1}"
    local var="${2}"
    local default="${3:-}"

    (
        set -e
        source "${cfg}"
        if [ -v ${var} ]
        then
            value="${!var}"
            [ -z "${value}" ] && value="${default}"
            echo "${value}"
            exit 0
        else
            echo "${default}"
            exit 1
        fi
    )
    return $?
}


check_cfg() {
    local root="${1}"
    local cfg="${2}"

    local rvalue
    local p

    if [ ! -r "${cfg}" ]
    then
        error_log "Cannot read/found backup configuration file '${cfg}'" 1005
        return 1005
    else
        echo_log "Reading backup configuration file '${cfg}' ..."
    fi
    p=$(read_cfg_param "${cfg}" FS)
    rvalue=$?
    if [ "${rvalue}" -ne "0" ] || [ -z "${p}" ]
    then
        fs=$(get_mountpoint_fs "${root}")
        rvalue=$?
        if [ "${rvalue}" -ne "0" ] || [ -z "${fs}" ]
        then
            error_log "Unknown filesystem type for mountpoint ${root}" 1010
            return 1010
        fi
    fi
    if type -t "${fs}_check" > /dev/null 2>&1
    then
        if ! ${fs}_check "${root}" > /dev/null 2>&1
        then
            error_log "${root} is not a valid ${fs} filesystem mountpoint!" 1011
            return 1011
        fi
    else
        error_log "${root} filesystem ${fs} is not supported by this program!" 1012
        return 1012
    fi
    p=$(read_cfg_param "${cfg}" SNAPSHOTS_PATH)
    rvalue=$?
    if [ "${rvalue}" -ne "0" ] || [ -z "${p}" ]
    then
        error_log "SNAPSHOTS_PATH not defined in configuration file '${cfg}'" 1006
        return 1006
    fi
    p=$(read_cfg_param "${cfg}" BACKUPS_DST)
    rvalue=$?
    if [ "${rvalue}" -ne "0" ] || [ -z "${p}" ]
    then
        error_log "BACKUPS_DST not defined in configuration file '${cfg}'" 1006
        return 1006
    fi
    p=$(read_cfg_param "${cfg}" BACKUPS_TOOL)
    if [ "${rvalue}" -ne "0" ] || [ -z "${p}" ]
    then
        error_log "BACKUPS_TOOL not defined in configuration file '${cfg}'" 1006
        return 1006
    fi
    return 0
}


manage_init() {
    local root="${1}"

    local tool="${BACKUP_TOOL_DEFAULT}"
    local cfg="${root}/${BACKUP_CFG}"
    local snapshots_path="$(dirname ${root})/.snapshots/$(basename ${root})"
    local tool_cfg="${BACKUP_TOOL_DEFAULT_CFG}"
    local backup_dst_file=$(mktemp -u)
    local backup_dst
    local rvalue=0
    local fs

    fs=$(get_mountpoint_fs "${root}")
    rvalue=$?
    if [ "${rvalue}" -ne "0" ] || [ -z "${fs}" ]
    then
        error_log "Unknown filesystem type for mountpoint ${root}" 1010
        return 1010
    else
        if type -t "${fs}_check" > /dev/null 2>&1
        then
            if ! ${fs}_check "${root}" > /dev/null 2>&1
            then
                error_log "${root} is not a valid ${fs} filesystem mountpoint!" 1011
                return 1011
            fi
        else
            error_log "${root} filesystem ${fs} is not supported by this program!" 1012
            return 1012
        fi
    fi
    echo_log "Performing ${tool} configuration in ${tool_cfg} ... "
    ${tool}_init "${tool_cfg}" "${backup_dst_file}"
    backup_dst=$(cat "${backup_dst_file}" | head -n 1)
    rm -f "${backup_dst_file}"
    if [ -z "${backup_dst}" ]
    then
        error_log "No ${tool} remote for backup destination defined!" 1007
        return 1007
    else
        echo_log "Getting first ${tool} remote for backup destination: '${backup_dst}'"
    fi
    if [ -r "${cfg}" ]
    then
        error_log "Configuration file '${cfg}' exists. I refuse to overwrite it" 0
        return 0
    fi
    backup_dst="${backup_dst}/backups/$(hostname -s)/$(basename ${root})"
    echo_log "Backup destination set to '${backup_dst}'"
    echo_log "Creating main configuration file ... "
    mkdir -p $(dirname "${cfg}")
    mkdir -p "${snapshots_path}"
    cat <<EOF >"${cfg}"
# Force a filesystem type. Set up to skip filesystem checks and force a type.
#FS=btrfs

# Path where snapshots are place in the filesystem. It can be a absolute path
# (within filesystem tree) or relative path to the filesystem mountpoint.
SNAPSHOTS_PATH="${snapshots_path}"

# Number of snapshots before performing a backup. Backups are done when the
# index of a snapshot is 1 (sufix #1, e.g. a snapshot '18.10.08-1-1539034830#1')
# 0 disables this feature, all snapshots will be backup.
SNAPSHOTS_INDEXES=6

# How many snapshots should remaing available? Warning, seting this parameter to
# 0 also causes SNAPSHOTS_INDEXES gets disabled (0).
SNAPSHOTS_KEEP=1

# Programs to un before (stat) and after (end) launching a snapshot
# They should exit with 0 in order to continue. Please wrap the commands with
# quotes!
#SNAPSHOTS_HOOK_START="/bin/true"
#SNAPSHOTS_HOOK_END="/bin/true"

# Tool to perform backups.
BACKUPS_TOOL=${tool}

# Destination of (remote) backups (using BACKUPS_TOOL)
BACKUPS_DST="${backup_dst}"

# If rclone config is not in the standard location, indicate it here
RCLONE_CONFIG="${tool_cfg}"

# Amount of recent backups to keep without applying the removal policy. Useful
# more than one bakup per day is being done. After this amount of backups,
# the policy will keep one per day.
BACKUPS_INITIAL_KEEP=1

# Amount of daily backups to keep. For example, to keep one backup per day during
# a week, set 7, to keep 2 weeks of daily backups, set 14
BACKUPS_DAILY_KEEP=7

# After BACKUPS_DAILY_KEEP, the policy will keep one per week. This defines
# which day will be kept (0 is Sunday)
BACKUPS_KEEP_DAY=0

# Amount of weekly bakups to keep. Only one backup per day (day == BACKUPS_KEEP_DAY)
# is kept after BACKUPS_DAILY_KEEP. How many of these? (4 means, 4 weekly backups,
# 4 per month)
BACKUPS_WEEKLY_KEEP=4

# One backup per month will be kept after BACKUPS_WEEKLY_KEEP, how many of these
# monthly backups should I keep?
BACKUPS_MONTHLY_KEEP=6

# Programs to un before (stat) and after (end) launching a backup
# They should exit with 0 in order to continue. Please wrap the commands with
# quotes!
#BACKUPS_HOOK_START="/bin/true"
#BACKUPS_HOOK_END="/bin/true"

# Restore hook scripts
#RESTORE_HOOK_START
#RESTORE_HOOK_END
EOF
    echo_log "Configuration file ${cfg} created!"
    return ${rvalue}
}


# Gets a list of snapshot names (with a specific format timestamp $(date +'%y.%V.%w.%d-%s'))
# and omits the ones which should not be deleted, returning via stdout the backups
# to be deleted
backup_policy_delete() {
    local number_backups_initial_keep="${1}"
    local number_backups_daily_keep="${2}"
    local number_backups_weekly_keep="${3}"
    local number_backups_monthly_keep="${4}"
    local backup_keep_day="${5}"

    awk \
        -v keep_initial=${number_backups_initial_keep} \
        -v keep_daily=${number_backups_daily_keep} \
        -v keep_weekly=${number_backups_weekly_keep} \
        -v keep_monthly=${number_backups_monthly_keep} \
        -v keep_day=${backup_keep_day} \
    'BEGIN {
        previous_day_month=-1;
        previous_month=-1;
        day_counter=0;
        week_counter=0;
        month_counter=0;
        FS="-";
        RS="[ \n]";
        ORS=" ";
    } {
        if (NR > keep_initial) {
            split($1,a,".");
            day_week=$2;
            day_month=a[3];
            month=a[2];
            # keep one backup per day, delete the rest in the same day
            if (day_month != previous_day_month) {
                previous_day_month=day_month;
            } else {
                print $0;
                next;
            }
            day_counter+=1;
            if (day_counter > keep_daily) {
                # keep one backup per week
                if (day_week != keep_day) {
                    print $0;
                    next;
                }
                week_counter+=1;
                if (week_counter > keep_weekly) {
                    # keep one backup per month
                    if (month != previous_month) {
                        previous_month=month;
                    } else {
                        print $0;
                        next;
                    }
                    month_counter+=1;
                    if (month_counter > keep_monthly) {
                        print $0;
                        next;
                    }
                }
            }
        }
    }'
}


hook() {
    local cmd="${1}"
    local kind="${2}"
    shift 2
    local args="${@}"

    local rvalue=0
    if [ -n "${cmd}" ]
    then
        local rvalue
        echo_log "HOOK[${kind}]: ${cmd} ${args}"
        (
            ${cmd} ${kind} ${args} 2>&1 | pipe_log
            exit ${PIPESTATUS[0]}
        ) &
        wait $!
        rvalue=$?
        echo_log "HOOK[${kind}]: exit ${rvalue}"
    fi
    return ${rvalue}
}


###


snapshot_create() {
    local fs="${1}"
    local root="${2}"
    local snapshot_path="${3}"
    local name="${4}"
    local cfg="${5}"
    local hooks_skip="${6}"

    local rvalue
    local hook_rvalue
    local output
    local snapshots
    local index=0
    local snapshot_listf=$(mktemp)
    local snapshot_max_index=$(read_cfg_param "${cfg}" SNAPSHOTS_INDEXES "0")
    local hook_start=""
    local hook_end=""

    if [ "${hooks_skip}" == "0" ]
    then
        hook_start=$(read_cfg_param "${cfg}" SNAPSHOTS_HOOK_START)
        hook_end=$(read_cfg_param "${cfg}" SNAPSHOTS_HOOK_END)
    fi
    echo_log "Getting list of current snapshots of [${fs}]${root} in '${snapshot_path}' ... "
    ${fs}_snapshot_list "${root}" "${snapshot_path}" "${snapshot_listf}"
    rvalue=$?
    if [ "${rvalue}" -ne "0" ]
    then
        rm -f ${snapshot_listf}
        error_log "Cannot get list of current snapshots" ${rvalue}
        return ${rvalue}
    fi
    snapshots=$(cat ${snapshot_listf})
    rm -f ${snapshot_listf}
    if [ "${snapshot_max_index}" -ne "0" ]
    then
        output=$(echo "${snapshots}" | awk '{ if (NR == 1) print $1 }')
        if [ -n "${output}" ]
        then
            index=$(echo "${output}" | awk '{ split($1,a,"#"); print a[2] }')
            if [ -z "${index}" ]
            then
                index=1
            else
                index=$((index+1))
                [ "${index}" -gt "${snapshot_max_index}" ] && index=1
            fi
        else
            index=1
        fi
        name="${name}#${index}"
        echo_log "Creating new snapshot in '${snapshot_path}' with index ${index} ... "
    else
        echo_log "Creating new snapshot in '${snapshot_path}' ... "
    fi
    hook "${hook_start}" "snapshot" "${root}" "${snapshot_path}" "${name}"
    hook_rvalue=$?
    if [ "${hook_rvalue}" -ne "0" ]
    then
        error_log "Stopping execution, hook failed!"  ${hook_rvalue}
        return ${hook_rvalue}
    fi
    ${fs}_snapshot_create "${root}" "${snapshot_path}" "${name}"
    rvalue=$?
    if [ "${rvalue}" -ne "0" ]
    then
        error_log "Snapshot of [${fs}]${root} not created!" ${rvalue}
    else
        echo_log "Snapshot of [${fs}]${root} '${name}' successfully created on path ${snapshot_path}"
    fi
    hook "${hook_end}" "snapshot" "${root}" "${snapshot_path}" "${name}" "${rvalue}"
    hook_rvalue=$?
    if [ "${hook_rvalue}" -ne "0" ]
    then
        error_log "Stopping execution, hook failed!"  ${hook_rvalue}
        return ${hook_rvalue}
    fi
    return ${rvalue}
}


cleanup_snapshots() {
    local fs="${1}"
    local root="${2}"
    local snapshot_path="${3}"
    local cfg="${4}"
    shift 4
    local names=("${@}")

    local rvalue
    local output
    local snapshots
    local snapshots_delete
    local error=0
    local rvalue_last_error=0
    local counter=0
    local snapshot_listf=$(mktemp)
    local snapshot_counter_keep=$(read_cfg_param "${cfg}" SNAPSHOTS_KEEP "3")

    echo_log "Cleaning up snapshots of [${fs}]${root} on ${snapshot_path} ... "
    ${fs}_snapshot_list "${root}" "${snapshot_path}" "${snapshot_listf}"
    rvalue=$?
    if [ "${rvalue}" -ne "0" ]
    then
        rm -f ${snapshot_listf}
        error_log "Cannot get list of current snapshots" ${rvalue}
        return ${rvalue}
    fi
    snapshots=$(cat ${snapshot_listf})
    rm -f ${snapshot_listf}
    if [ "${#names[@]}" -eq "0" ]
    then
        # If no name given, take the oldest after keep-number snapshots
        snapshots_delete=$(echo "${snapshots}" | awk -v keep=${snapshot_counter_keep} '{ if (NR > keep) print $1 }' | xargs)
        if [ -z "${snapshots_delete}" ]
        then
            echo_log "No more than ${snapshot_counter_keep} snapshots found. Nothing to delete!"
            return 0
        fi
    else
        for snapshot_name in "${names[@]}"
        do
            output=$(echo "${snapshots}" | awk -v s="${snapshot_name}" '{ if ($1 ~ s) print $1 }')
            if [ -n "${output}" ]
            then
                snapshots_delete="${snapshots_delete} ${output}"
            else
                error_log "Snapshot '${snapshot_name}' in ${snapshot_path} not found!" 1101
                return 1101
            fi
        done
    fi
    echo_log "Snapshots to delete because of policy in '${cfg}': ${snapshots_delete}"
    for snapshot_name in ${snapshots_delete}
    do
        echo_log "Deleting old snapshot '${snapshot_name}' in path ${snapshot_path} ... "
        ${fs}_snapshot_delete "${root}" "${snapshot_path}" "${snapshot_name}"
        rvalue=$?
        if [ "${rvalue}" -ne "0" ]
        then
            error_log "Snapshot '${snapshot_name}' not deleted" ${rvalue}
            error=$((error+1))
            rvalue_last_error=${rvalue}
        else
            echo_log "Snapshot '${snapshot_name}' deleted"
            counter=$((counter+1))
        fi
    done
    if [ "${error}" -ne "0" ]
    then
        error_log "${error} errors deleting snapshots of [${fs}]${root}!" ${rvalue_last_error}
        rvalue=${rvalue_last_error}
    else
        echo_log "Successfully deleted ${counter} snapshots of [${fs}]${root}"
    fi
    return ${rvalue}
}


snapshot_backup() {
    local fs="${1}"
    local root="${2}"
    local snapshot_path="${3}"
    local snapshot_name="${4}"
    local cfg="${5}"
    local force="${6}"
    local hooks_skip="${7}"

    local rvalue
    local hook_rvalue
    local index
    local snapshot_full_path
    local backups_dst=$(read_cfg_param "${cfg}" BACKUPS_DST)
    local tool=$(read_cfg_param "${cfg}" BACKUPS_TOOL)
    local hook_start=""
    local hook_end=""

    if [ "${hooks_skip}" == "0" ]
    then
        hook_start=$(read_cfg_param "${cfg}" BACKUPS_HOOK_START)
        hook_end=$(read_cfg_param "${cfg}" BACKUPS_HOOK_END)
    fi
    if [[ "${snapshot_name}" =~ '#' ]] && [ "${force}" == "0" ]
    then
        index=$(echo "${snapshot_name}" | awk '{ split($1,a,"#"); print a[2] }')
        if [ -z "${index}" ]
        then
            error_log "Latest created snapshot '${snapshot_name} not found!" 1100
            return 1100
        fi
        if [ "${index}" -ne "1" ]
        then
            echo_log "Skipping backup from snapshot '${snapshot_name}' by index (${index} not 1)"
            return 0
        fi
    fi
    # Snapshot prepare for backup!
    ${fs}_snapshot_mount "${root}" "${snapshot_path}" "${snapshot_name}"
    rvalue=$?
    snapshot_full_path="${snapshot_path}/${snapshot_name}"
    if [ "${rvalue}" -ne "0" ]
    then
        error_log "Could not prepare snapshot in '${snapshot_full_path}' to perform backup" ${rvalue}
        return ${rvalue}
    fi
    if [ ! -d "${snapshot_full_path}" ]
    then
        error_log "Snapshot on path '${snapshot_full_path}' not available!" 1102
        return 1102
    fi
    echo_log "Performing backup for [${fs}]${root} from snapshot '${snapshot_name}' to '[${tool}]${backups_dst}' ... "
    hook "${hook_start}" "backup" "${root}" "${snapshot_full_path}" "${backups_dst}"
    hook_rvalue=$?
    if [ "${hook_rvalue}" -ne "0" ]
    then
        error_log "Stopping execution, hook failed!"  ${hook_rvalue}
        return ${hook_rvalue}
    fi
    ${tool}_backup_run "${root}" "${cfg}" "${snapshot_full_path}" "${backups_dst}"
    rvalue=$?
    if [ "${rvalue}" -ne "0" ]
    then
        error_log "Backup from snapshot '${snapshot_full_path}' to '[${tool}]${backups_dst}' not done!" ${rvalue}
    else
        echo_log "Backup from snapshot path '${snapshot_full_path}' to '[${tool}]${backups_dst}' successfully done!"
    fi
    hook "${hook_end}" "backup" "${root}" "${snapshot_full_path}" "${backups_dst}" "${rvalue}"
    hook_rvalue=$?
    # Snapshot umount for backup!
    ${fs}_snapshot_umount "${root}" "${snapshot_path}" "${snapshot_name}"
    rvalue=$?
    if [ "${hook_rvalue}" -ne "0" ]
    then
        error_log "Stopping execution, hook failed!"  ${hook_rvalue}
        return ${hook_rvalue}
    fi
    if [ "${rvalue}" -ne "0" ]
    then
        error_log "Could not umount snapshot in '${snapshot_full_path}' to finish backup" ${rvalue}
        return ${rvalue}
    fi
    return ${rvalue}
}


cleanup_backups() {
    local fs="${1}"
    local root="${2}"
    local cfg="${3}"

    local rvalue
    local backup_list
    local backup_delete
    local error=0
    local counter=0
    local rvalue_last_error=0

    local backups_dst=$(read_cfg_param "${cfg}" BACKUPS_DST)
    local tool=$(read_cfg_param "${cfg}" BACKUPS_TOOL)
    local initial_keep=$(read_cfg_param "${cfg}" BACKUPS_INITIAL_KEEP "1")
    local daily_keep=$(read_cfg_param "${cfg}" BACKUPS_DAILY_KEEP "7")
    local weekly_keep=$(read_cfg_param "${cfg}" BACKUPS_WEEKLY_KEEP "4")
    local monthly_keep=$(read_cfg_param "${cfg}" BACKUPS_MONTHLY_KEEP "6")
    local keep_day=$(read_cfg_param "${cfg}" BACKUPS_KEEP_DAY "0")
    local outputf=$(mktemp)

    echo_log "Cleaning up remote backups for ${root} in '[${tool}]${backups_dst}' ..."
    ${tool}_backup_list "${root}" "${cfg}" "${backups_dst}" "${outputf}"
    rvalue=$?
    if [ "${rvalue}" -ne "0" ]
    then
        rm -f ${outputf}
        error_log "Cannot get list of backups" ${rvalue}
        return ${rvalue}
    fi
    backup_list=$(cat ${outputf} | xargs)
    rm -f ${outputf}
    if [ -z "${backup_list}" ]
    then
        echo_log "No remote backups have been found in '[${tool}]${backups_dst}'!"
        return 0
    fi
    echo_log "List of ${tool} backups in '${backups_dst}': ${backup_list}"
    backup_delete=$(echo "${backup_list}" | backup_policy_delete ${initial_keep} ${daily_keep} ${weekly_keep} ${monthly_keep} ${keep_day})
    if [ -z "${backup_delete}" ]
    then
        echo_log "Given the current policy in '${cfg}', there are no backups to delete!"
        return 0
    fi
    echo_log "Backups to delete because of policy in '${cfg}': ${backup_delete}"
    for delete in ${backup_delete}
    do
        echo_log "Deleting old backup '[${tool}]${backups_dst}/${delete}' ..."
        ${tool}_backup_delete "${root}" "${cfg}" "${delete}" "${backups_dst}"
        rvalue=$?
        if [ "${rvalue}" -ne "0" ]
        then
            error_log "Cannot delete backup '${delete}'" ${rvalue}
            error=$((error+1))
            rvalue_last_error=${rvalue}
        else
            echo_log "Backup '${delete}' deleted"
            counter=$((counter+1))
        fi
    done
    if [ "${error}" -ne "0" ]
    then
        error_log "Something went wrong deleting backups of ${root} in '[${tool}]${backups_dst}'!" ${rvalue_last_error}
        rvalue=${rvalue_last_error}
    else
        echo_log "Successfully deleted ${counter} old backups of ${root} in '[${tool}]${backups_dst}'"
    fi
    return ${rvalue}
}


manage_snapshots_backup() {
    local fs="${1}"
    local root="${2}"
    local snapshot_path="${3}"
    local cfg="${4}"
    local force_backup="${5}"
    local hooks_snapshot_skip="${6}"
    local hooks_backup_skip="${7}"

    local rvalue
    local rvalue_cleanup
    local rvalue_backup
    local snapshots
    local last_snapshot
    local name="${POLICY_DATE}"
    local snapshot_listf=$(mktemp -u)

    # Create snapshot
    snapshot_create "${fs}" "${root}" "${snapshot_path}" "${name}" "${cfg}" "${hooks_snapshot_skip}" || return $?
    # Manage
    if [ "${force_backup}" == "0" ]
    then
        echo_log "Checking policy to see if last snapshot on [${fs}]${root} needs to be backup ..."
    else
        echo_log "Forcing bakup of latest snapshot on [${fs}]${root} ..."
    fi
    ${fs}_snapshot_list "${root}" "${snapshot_path}" "${snapshot_listf}"
    rvalue=$?
    last_snapshot=$(cat ${snapshot_listf} | awk -v name="${name}" '{ if ($1 ~ name) print $1 }')
    rm -f "${snapshot_listf}"
    if [ "${rvalue}" -ne "0" ] || [ -z "${last_snapshot}" ]
    then
        rm -f "${snapshot_listf}"
        error_log "Cannot get list of current snapshots" ${rvalue}
        return ${rvalue}
    fi
    snapshot_backup "${fs}" "${root}" "${snapshot_path}" "${last_snapshot}" "${cfg}" "${force_backup}" "${hooks_backup_skip}"
    rvalue_backup=$?
    # Delete old snapshots
    cleanup_snapshots "${fs}" "${root}" "${snapshot_path}" "${cfg}"
    rvalue_cleanup=$?
    [ "${rvalue_backup}" -ne "0" ] && return ${rvalue_backup}
    [ "${rvalue_cleanup}" -ne "0" ] && return ${rvalue_cleanup}
    return 0
}


manage_backup() {
    local root="${1}"
    local force_backup="${2}"
    local hooks_snapshot_skip="${3}"
    local hooks_backup_skip="${4}"

    local fs
    local rvalue_cleanup
    local rvalue_backup
    local snapshot_path
    local cfg="${root}/${BACKUP_CFG}"

    check_cfg "${root}" "${cfg}" || return $?
    fs=$(read_cfg_param "${cfg}" FS)
    [ -z "${fs}" ] && fs=$(get_mountpoint_fs "${root}")
    snapshot_path=$(read_cfg_param "${cfg}" SNAPSHOTS_PATH)
    case "${snapshot_path}" in
        /*) snapshot_path="${snapshot_path%/}" ;;
        *)  snapshot_path="${root}/${snapshot_path%/}" ;;
    esac
    manage_snapshots_backup "${fs}" "${root}" "${snapshot_path}" "${cfg}" "${force_backup}" "${hooks_snapshot_skip}" "${hooks_backup_skip}"
    rvalue_backup=$?
    cleanup_backups "${fs}" "${root}" "${cfg}"
    rvalue_cleanup=$?
    [ "${rvalue_backup}" -ne "0" ] && return ${rvalue_backup}
    [ "${rvalue_cleanup}" -ne "0" ] && return ${rvalue_cleanup}
    return 0
}


### list #######################################################################

list_snapshots_backups() {
    local root="${1}"

    local fs
    local tool
    local snapshot_path
    local backups_dst
    local cfg="${root}/${BACKUP_CFG}"
    local rvalue
    local output_list=$(mktemp -u)

    check_cfg "${root}" "${cfg}" || return $?
    fs=$(read_cfg_param "${cfg}" FS)
    [ -z "${fs}" ] && fs=$(get_mountpoint_fs "${root}")
    snapshot_path=$(read_cfg_param "${cfg}" SNAPSHOTS_PATH)
    case "${snapshot_path}" in
        /*) snapshot_path="${snapshot_path%/}" ;;
        *)  snapshot_path="${root}/${snapshot_path%/}" ;;
    esac
    backups_dst=$(read_cfg_param "${cfg}" BACKUPS_DST)
    tool=$(read_cfg_param "${cfg}" BACKUPS_TOOL)

    echo_log "List of ${root} snapshots in ${snapshot_path}"
    ${fs}_snapshot_list "${root}" "${snapshot_path}" "${output_list}"
    rvalue=$?
    if [ "${rvalue}" -ne "0" ]
    then
        rm -f "${output_list}"
        error_log "Cannot get list of current snapshots" ${rvalue}
        return ${rvalue}
    fi
    cat "${output_list}" |  awk '{ print "···················> "$0}'
    echo_log "List of ${root} backups in ${backups_dst}"
    ${tool}_backup_list "${root}" "${cfg}" "${backups_dst}" "${output_list}"
    rvalue=$?
    if [ "${rvalue}" -ne "0" ]
    then
        rm -f ${output_list}
        error_log "Cannot get list of backups" ${rvalue}
        return ${rvalue}
    fi
    cat "${output_list}" | awk '{ print "···················> "$0}'
    rm -f "${output_list}"
    return 0
}


### Restore functions ##########################################################


backup_restore() {
    local root="${1}"
    local backups_dst="${2}"
    local restore_name="${3}"
    local tool="${4}"
    local cfg="${5}"
    local keep_orig="${6}"
    local hooks_skip="${7}"

    local rvalue
    local backup_list
    local backup_name
    local outputf=$(mktemp)
    local hook_start=""
    local hook_end=""
    local hook_rvalue

    if [ "${hooks_skip}" == "0" ]
    then
        hook_start=$(read_cfg_param "${cfg}" RESTORE_HOOK_START)
        hook_end=$(read_cfg_param "${cfg}" RESTORE_HOOK_END)
    fi
    echo_log "Getting remote backups for ${root} on '[${tool}]${backups_dst}' ..."
    ${tool}_backup_list "${root}" "${cfg}" "${backups_dst}" "${outputf}"
    rvalue=$?
    if [ "${rvalue}" -ne "0" ]
    then
        rm -f "${outputf}"
        error_log "Cannot get list of backups on '[${tool}]${backups_dst}'" ${rvalue}
        return ${rvalue}
    fi
    backup_list=$(cat "${outputf}")
    rm -f "${outputf}"
    echo_log "List of backups found: $(echo ${backup_list} | xargs)"
    if [ -z "${restore_name}" ] || [ "${restore_name}" == "last" ] || [ "${restore_name}" == "latest" ]
    then
        backup_name=$(echo "${backup_list}" | awk '{ if (NR == 1) print $1 }')
        if [ -z "${backup_name}" ]
        then
            error_log "No remote backups have been found for on '[${tool}]${backups_dst}'!" 2003
            return 2003
        fi
    else
        backup_name=$(echo "${backup_list}" | awk -v s="${restore_name}" '{ if ($1 ~ s) print $1 }')
        if [ -z "${backup_name}" ]
        then
            error_log "No backups matching '${restore_name}' found on '[${tool}]${backups_dst}'!" 2003
            return 2003
        fi
    fi
    echo_log "Performing restoring on ${root} from '${restore_name}' backup '[${tool}]${backups_dst}/${backup_name}' ..."
    hook "${hook_start}" "backup" "${root}" "${backups_dst}" "${backup_name}" "${keep_orig}"
    hook_rvalue=$?
    if [ "${hook_rvalue}" -ne "0" ]
    then
        error_log "Stopping execution, hook failed!"  ${hook_rvalue}
        return ${hook_rvalue}
    fi
    ${tool}_backup_restore "${root}" "${cfg}" "${backups_dst}" "${backup_name}" "${keep_orig}"
    rvalue=$?
    if [ "${rvalue}" -ne "0" ]
    then
        error_log "Something went wrong restoring backup '${restore_name}' ~ '${backup_name}'" ${rvalue}
    else
        echo_log "Backup '${restore_name}' ~ '${backup_name}' successfully restored on ${root}!"
    fi
    hook "${hook_end}" "backup" "${root}" "${backups_dst}" "${backup_name}" "${keep_orig}" "${rvalue}"
    hook_rvalue=$?
    if [ "${hook_rvalue}" -ne "0" ]
    then
        error_log "Stopping execution, hook failed!"  ${hook_rvalue}
        return ${hook_rvalue}
    fi
    return ${rvalue}
}


snapshot_restore() {
    local fs="${1}"
    local root="${2}"
    local snapshot_path="${3}"
    local restore_name="${4}"
    local cfg="${5}"
    local keep_orig="${6}"
    local hooks_skip="${7}"

    local rvalue
    local output_snapshot_list=$(mktemp)
    local snapshots
    local snapshot_name
    local snapshot_dir
    local hook_start=""
    local hook_end=""
    local hook_rvalue

    if [ "${hooks_skip}" == "0" ]
    then
        hook_start=$(read_cfg_param "${cfg}" RESTORE_HOOK_START)
        hook_end=$(read_cfg_param "${cfg}" RESTORE_HOOK_END)
    fi
    echo_log "Getting list of snapshots of [${fs}]${root} on ${snapshot_path} ... "
    ${fs}_snapshot_list "${root}" "${snapshot_path}" "${output_snapshot_list}"
    rvalue=$?
    if [ "${rvalue}" -ne "0" ]
    then
        rm -f ${output_snapshot_list}
        error_log "Cannot get list of snapshots" ${rvalue}
        return ${rvalue}
    fi
    snapshots=$(cat ${output_snapshot_list})
    rm -f ${output_snapshot_list}
    echo_log "List of snapshots on ${snapshot_path}: $(echo ${snapshots} | xargs)"
    if [ -z "${restore_name}" ] || [ "${restore_name}" == "last" ] || [ "${restore_name}" == "latest" ]
    then
        snapshot_name=$(echo "${snapshots}" | awk '{ if (NR == 1) print $1 }')
        if [ -z "${snapshot_name}" ]
        then
            echo_log "No snapshots matching '${restore_name}' found on ${snapshot_path}!" 2002
            return 2002
        fi
    else
        snapshot_name=$(echo "${snapshots}" | awk -v s="${restore_name}" '{ if ($1 ~ s) print $1 }')
        if [ -z "${snapshot_name}" ]
        then
            error_log "Snapshot '${restore_name}' not found in ${snapshot_path}!" 2002
            return 2002
        fi
    fi
    snapshot_dir="${snapshot_path}/${snapshot_name}"
    echo_log "Performing restoring ${root} from '${restore_name}' snapshot path '${snapshot_dir}' ..."
    hook "${hook_start}" "snapshot" "${root}" "${snapshot_dir}" "${keep_orig}"
    hook_rvalue=$?
    if [ "${hook_rvalue}" -ne "0" ]
    then
        error_log "Stopping execution, hook failed!"  ${hook_rvalue}
        return ${hook_rvalue}
    fi
    ${fs}_snapshot_restore "${root}" "${snapshot_dir}" "${keep_orig}"
    rvalue=$?
    if [ "${rvalue}" -ne "0" ]
    then
        error_log "Something went wrong restoring snapshot '${restore_name}' ~ '${snapshot_name}'" ${rvalue}
    else
        echo_log "Snapshot '${restore_name}' ~ '${snapshot_name}' successfully restored on ${root}!"
    fi
    hook "${hook_end}" "snapshot" "${root}" "${snapshot_dir}" "${keep_orig}"
    hook_rvalue=$?
    if [ "${hook_rvalue}" -ne "0" ]
    then
        error_log "Stopping execution, hook failed!"  ${hook_rvalue}
        return ${hook_rvalue}
    fi
    return ${rvalue}
}


manage_restore() {
    local root="${1}"
    local nohook="${2}"
    local keep="${3:-1}"

    local restored=0
    local rvalue
    local fs
    local tool
    local snapshot_path
    local backups_dst
    local backup_cfg="${root}/${BACKUP_CFG}"
    local restore_ctl="${root}/${RESTORE_CFG}"
    local restore_name
    local from="any"
    local restore_ctl_done

    check_cfg "${root}" "${backup_cfg}" || return $?
    fs=$(read_cfg_param "${backup_cfg}" FS)
    [ -z "${fs}" ] && fs=$(get_mountpoint_fs "${root}")
    snapshot_path=$(read_cfg_param "${backup_cfg}" SNAPSHOTS_PATH)
    case "${snapshot_path}" in
        /*) snapshot_path="${snapshot_path%/}" ;;
        *)  snapshot_path="${root}/${snapshot_path%/}" ;;
    esac
    backups_dst=$(read_cfg_param "${backup_cfg}" BACKUPS_DST)
    tool=$(read_cfg_param "${backup_cfg}" BACKUPS_TOOL)

    if [ ! -r "${restore_ctl}" ]
    then
        error_log "Restore control file '${restore_ctl}' not found!" 2000
        return 2000
    else
        restore_name=$(cat ${restore_ctl} | awk '{ if (NR == 1) print $1 }')
        grep -qi "snapshot" ${restore_ctl} && from="snapshot"
        grep -qi "backup" ${restore_ctl} && from="backup"
        grep -qi "nokeep" ${restore_ctl} && keep=0
        grep -qi "nohook" ${restore_ctl} && nohook=1
        [ -z "${from}" ] && from="any"
        echo_log "Request to restore backup '${restore_name}' from '${from}' source in ${root} ... "
    fi
    if [ -z "${restore_name}" ]
    then
        error_log "Restore control file '${restore_ctl}' empty?" 2001
        return 2001
    fi
    if [ "${from}" == "any" ] || [ "${from}" == "snapshot" ]
    then
        snapshot_restore "${fs}" "${root}" "${snapshot_path}" "${restore_name}" "${backup_cfg}" "${keep}" "${nohook}"
        rvalue=$?
        [ "${rvalue}" -eq "0" ] && restored=1
    fi
    if [ "${restored}" -eq "0" ] && [ "${from}" == "any" -o "${from}" == "backup" ]
    then
        backup_restore "${root}" "${backups_dst}" "${restore_name}" "${tool}" "${backup_cfg}" "${keep}" "${nohook}"
        rvalue=$?
        [ "${rvalue}" -eq "0" ] && restored=2
    fi
    if [ "${rvalue}" -eq "0" ] && [ -r "${restore_ctl}" ]
    then
        restore_ctl_done="${restore_ctl}.$(date +'%y.%m.%d-%w-%s')"
        echo_log "Renaming restore control file '${restore_ctl}' to '${restore_ctl_done}'"
        mv "${restore_ctl}" "${restore_ctl_done}"
    fi
    return ${rvalue}
}


### Process control functions ##################################################


finish() {
    local rvalue=$?
    local files=("${@}")

    for f in "${files[@]}"
    do
        echo_log "Deleting temp file ${f}"
        rm -f "${f}"
    done
    echo_log "EXIT rc=${rvalue}"
    exit ${rvalue}
}


run() {
    local subcommand="${1}"
    local folder="${2%/}"
    shift 2
    local args="${@}"

    local pid
    local rvalue
    local lock="${folder}/${BACKUP_LOCK}"
    local mypid=$$

    if [ ! -d "${folder}" ]
    then
        error_log "Mountpoint to operate not found or specified!" 1000
        return 1000
    fi
    if [ ! "$(id -u)" == "0" ]
    then
        error_log "Program not running as root" 1001
        return 1001
    fi
    if [ -r "${lock}" ]
    then
        echo_log "Wait, wait ... It seems there is a lock file '${lock}'. Checking ..."
        pid=$(cat "${lock}")
        if ps -p ${pid} > /dev/null 2>&1
        then
            rvalue=1002
            error_log "There is a backup/restore process still running on '${folder}' with pid ${pid}." ${rvalue}
        else
            rvalue=1003
            error_log "Lock file '${lock}' exists, but backup/restore process wid pid ${pid} is not running!." ${rvalue}
        fi
    else
        echo ${mypid} > "${lock}" 2>/dev/null
        rvalue=$?
        pid=$(cat "${lock}" 2>/dev/null)
        if [ "$?" -ne "0" ] || [ "${rvalue}" -ne "0" ] || [ "${pid}" -ne "${mypid}" ]
        then
            rvalue=1004
            error_log "Something went wrong writing pid to lock file '${lock}'." ${rvalue}
        else
            trap "finish ${lock}" SIGINT SIGTERM SIGKILL
            ${subcommand} "${folder}" ${args}
            rvalue=$?
        fi
        rm -f "${lock}"
    fi
    if [ "${rvalue}" -eq "0" ]
    then
       echo_log "RC=${rvalue} OK"
    else
       echo_log "RC=${rvalue} ERROR"
    fi
    return ${rvalue}
}


################################################################################

### RCLONE snapshots functions

rclone_init() {
    local cfg="${1}"
    local dstf="${2}"

    local cmd
    local dst
    (
        set -e
        cmd="${RCLONE} --config=${cfg} config"
        echo_log "RUN: ${cmd}"
        ${cmd} && ${RCLONE} --config=${cfg} listremotes > "${dstf}"
        return $?
    )
    return $?
}


rclone_backup_run() {
    local root="${1}"
    local cfg="${2}"
    local backup_src="${3}"
    local backup_dst="${4}"

    local rclone_cfg
    local cmd
    local dst
    (
        set -e
        source "${cfg}"
        rclone_cfg="${RCLONE_CONFIG}"
        dst=$(basename "${backup_src}")
        RCLONE="${BACKUPS_TOOL:-$RCLONE}"
        [ -n "${rclone_cfg}" ] && RCLONE="${RCLONE} --config=${rclone_cfg}"
        cmd="${RCLONE} -v copy --ignore-checksum --ignore-existing --ignore-size --ignore-times ${backup_src} ${backup_dst}/${dst} ${BACKUP_ARGS:-}"
        echo_log "RUN: ${cmd}"
        ${cmd} 2>&1 | pipe_log
        exit ${PIPESTATUS[0]}
    ) &
    wait $!
    return $?
}


rclone_backup_restore() {
    local root="${1}"
    local cfg="${2}"
    local backup_dst="${3}"
    local restore_name="${4}"
    local keep_orig="${5:-1}"

    local rclone_cfg
    local cmd
    local rvalue
    (
        set -e
        rvalue=0
        if [ "${keep_orig}" -eq "1" ]
        then
            cmd="tar -zcvf ${root}.backup-$(date +'%y.%m.%d-%w-%s').tgz ${root}"
            echo_log "RUN: ${cmd}"
            ${cmd} 2>&1 | pipe_log
            rvalue=${PIPESTATUS[0]}
        fi
        if [ "${rvalue}" -eq "0" ]
        then
            source "${cfg}"
            rclone_cfg="${RCLONE_CONFIG}"
            RCLONE="${BACKUPS_TOOL:-$RCLONE}"
            [ -n "${rclone_cfg}" ] && RCLONE="${RCLONE} --config=${rclone_cfg}"

            cmd="${RCLONE} -v sync ${backup_dst}/${restore_name} ${root} ${RESTORE_ARGS:-}"
            echo_log "RUN: ${cmd}"
            ${cmd} 2>&1 | pipe_log
            exit ${PIPESTATUS[0]}
        fi
        exit ${rvalue}
    ) &
    wait $!
    return $?
}


rclone_backup_list() {
    local root="${1}"
    local cfg="${2}"
    local backup_dst="${3}"
    local output="${4}"

    local rclone_cfg
    local cmd
    local rvalue
    (
        set -e
        source "${cfg}"
        rclone_cfg="${RCLONE_CONFIG}"
        RCLONE="${BACKUPS_TOOL:-$RCLONE}"
        [ -n "${rclone_cfg}" ] && RCLONE="${RCLONE} --config=${rclone_cfg}"

        cmd="${RCLONE} -v mkdir ${backup_dst}"
        ${cmd} >/dev/null 2>&1
        cmd="${RCLONE} lsf --dirs-only --format=p --dir-slash=false ${backup_dst}/"
        echo_log "RUN: ${cmd}"
        ${cmd} | sort >"${output}" 2> >(pipe_log)
        rvalue="${PIPESTATUS[0]}"
        exit ${rvalue}
    ) &
    wait $!
    return $?
}


rclone_backup_delete() {
    local root="${1}"
    local cfg="${2}"
    local name="${3}"
    local backup_dst="${4}"

    local rclone_cfg
    local cmd
    (
        set -e
        source "${cfg}"
        rclone_cfg="${RCLONE_CONFIG}"
        RCLONE="${BACKUPS_TOOL:-$RCLONE}"
        [ -n "${rclone_cfg}" ] && RCLONE="${RCLONE} --config=${rclone_cfg}"

        cmd="${RCLONE} -v purge ${backup_dst}/${name}"
        echo_log "RUN: ${cmd}"
        ${cmd} 2>&1 | pipe_log
        exit ${PIPESTATUS[0]}
    ) &
    wait $!
    return $?
}


### BTRFS snapshots functions


btrfs_check() {
    local root="${1}"

    local rvalue
    local cmd
    (
        set -e
        cmd="${BTRFS} subvolume show ${root}"
        echo_log "RUN: ${cmd}"
        ${cmd} >> "${PROGRAM_LOG}" 2>&1
        exit $?
    ) &
    wait $!
    return $?
}


btrfs_snapshot_create() {
    local root="${1}"
    local snapshot_path="${2}"
    local snapshot_name="${3}"

    local rvalue
    local cmd
    (
        set -e
        mkdir -p "${snapshot_path}"
        sync
        cmd="${BTRFS} subvolume snapshot -r ${root} ${snapshot_path}/${snapshot_name}"
        echo_log "RUN: ${cmd}"
        ${cmd} 2>&1 | pipe_log
        rvalue=${PIPESTATUS[0]}
        sync
        exit ${rvalue}
    ) &
    wait $!
    return $?
}


btrfs_snapshot_list() {
    local root="${1}"
    local snapshot_path="${2}"
    local output="${3}"

    local cmd
    # get the longest common path
    local lcpath=$(echo -e "${root}\n${snapshot_path}" | sed -e 's|$|/|;1{h;d;}' -e 'G;s|\(.*/\).*\n\1.*|\1|;h;$!d;s|/$||')
    (
        set -e
        cmd="${BTRFS} subvolume list -t -a -r --sort=-gen ${root}"
        echo_log "RUN: ${cmd}"
        ${cmd} | awk -v cm="${lcpath}" -v s="${snapshot_path}" 'NR > 2 { sub("<FS_TREE>",cm,$4); regex="^"s; if ($4 ~ regex) { n=split($4,a,"/"); print a[n]; } }' >"${output}" 2> >(pipe_log)
        exit ${PIPESTATUS[0]}
    ) &
    wait $!
    return $?
    # Sorted list
}


btrfs_snapshot_delete() {
    local root="${1}"
    local snapshot_path="${2}"
    local snapshot_name="${3}"

    local cmd
    (
        set -e
        cmd="${BTRFS} subvolume delete ${snapshot_path}/${snapshot_name}"
        echo_log "RUN: ${cmd}"
        ${cmd} 2>&1 | pipe_log
        exit ${PIPESTATUS[0]}
    ) &
    wait $!
    return $?
}


btrfs_snapshot_mount() {
    local root="${1}"
    local snapshot_path="${2}"
    local snapshot_name="${3}"

    # Prepare to perform a backup, do mount or something ...
    # Not needed in btrfs
    return 0
}


btrfs_snapshot_umount() {
    local root="${1}"
    local snapshot_path="${2}"
    local snapshot_name="${3}"

    # Not needed in btrfs
    return 0
}


btrfs_snapshot_restore() {
    local root="${1}"
    local snapshot_dir="${2}"
    local keep_orig="${3:-1}"

    local rvalue
    local cmd
    (
        set -e
        rvalue=0
        volume=''
        if mountpoint -q "${root}"
        then
            volume="${root}"
        else
            device=$(findmnt -k -l -n -t btrfs -o source --target ${root})
            subvolumeid=$(${BTRFS} subvolume show "${root}" | awk -v IGNORECASE=1 '/Subvolume ID/{ print $3 }')
            volume=$(findmnt -k -l -n -t btrfs -S "${device}" | awk -v volid="subvolid=${subvolumeid}" '{ if ($4 ~ volid) print $1 }')
            [ -z "${volume}" ] && echo_log "Unable to determine root subvolume for ${root}"
        fi
        if [ "${keep_orig}" -eq "1" ]
        then
            cmd="tar --exclude -zcvf ${root}.backup-$(date +'%y.%m.%d-%w-%s').tgz ${root}"
            echo_log "RUN: ${cmd}"
            ${cmd} 2>&1 | pipe_log
            rvalue=${PIPESTATUS[0]}
        fi
        if [ "${rvalue}" -eq "0" ]
        then
            cmd="mv -v ${root} ${root}.betterclone"
            echo_log "RUN: ${cmd}"
            ${cmd} 2>&1 | pipe_log
            rvalue=${PIPESTATUS[0]}
            [ "${rvalue}" -ne "0" ] && exit ${rvalue}
            cmd="${BTRFS} subvolume snapshot ${snapshot_dir} ${root}"
            echo_log "RUN: ${cmd}"
            ${cmd} 2>&1 | pipe_log
            rvalue=${PIPESTATUS[0]}
            [ "${rvalue}" -ne "0" ] && exit ${rvalue}
            if [ -n "${volume}" ]
            then
                cmd="umount ${volume} && mount ${volume}"
                echo_log "RUN: ${cmd}"
                ${cmd} 2>&1 | pipe_log
                rvalue=${PIPESTATUS[0]}
                [ "${rvalue}" -ne "0" ] && exit ${rvalue}
            fi
            cmd="${BTRFS} subvolume delete ${root}.betterclone"
            echo_log "RUN: ${cmd}"
            ${cmd} 2>&1 | pipe_log
            exit ${PIPESTATUS[0]}
        fi
        exit ${rvalue}
    ) &
    wait $!
    return $?
}


################################################################################


if [ "${0}" == "${BASH_SOURCE[0]}" ]
then
    # Delete of logs!
    FOLDER=""
    RVALUE=0
    SUBCOMMAND=""
    FORCE_BACKUP=0
    SKIP_HOOKS_SNAPSHOT=0
    SKIP_HOOKS_BACKUP=0
    SKIP_HOOKS_RESTORE=0
    RESTORE_KEEP_PREVIOUS=1
    # Parse main options
    while getopts ":h" opt
    do
        case "${opt}" in
            h)
                usage
                exit 0
            ;;
            :)
                die "Option -${OPTARG} requires an argument"
            ;;
        esac
    done
    shift $((OPTIND -1))
    SUBCOMMAND="${1}"
    shift                       # Remove 'subcommand' from the argument list
    FOLDER="${1%/}"
    shift                       # Remove folder
    OPTIND=0
    case "${SUBCOMMAND}" in
        # Parse options to each sub command
        ''|help)
            usage
            exit 0
        ;;
        list)
            run list_snapshots_backups "${FOLDER}"
            RVALUE=$?
        ;;
        init)
            run manage_init "${FOLDER}"
            RVALUE=$?
        ;;
        backup)
            for var in "${@}"
            do
                case "${var}" in
                    force) FORCE_BACKUP=1 ;;
                    nohooks) SKIP_HOOKS_SNAPSHOT=1; SKIP_HOOKS_BACKUP=1 ;;
                    skip-hooks-snapshot) SKIP_HOOKS_SNAPSHOT=1 ;;
                    skip-hooks-backup) SKIP_HOOKS_BACKUP=1 ;;
                    *) die "Unknown option '${var}'!" ;;
                esac
            done
            run manage_backup "${FOLDER}" "${FORCE_BACKUP}" "${SKIP_HOOKS_SNAPSHOT}" "${SKIP_HOOKS_BACKUP}"
            RVALUE=$?
        ;;
        restore)
            for var in "${@}"
            do
                case "${var}" in
                    nohooks) SKIP_HOOKS_RESTORE=1 ;;
                    skip-hooks-recover) SKIP_HOOKS_RESTORE=1 ;;
                    nokeep) RESTORE_KEEP_PREVIOUS=0 ;;
                    *) die "Unknown option '${var}'!" ;;
                esac
            done
            run manage_restore "${FOLDER}" "${SKIP_HOOKS_RESTORE}" "${RESTORE_KEEP_PREVIOUS}"
            RVALUE=$?
        ;;
        *)
            die "Unknown subcommand '${SUBCOMMAND}'!"
        ;;
    esac
    exit ${RVALUE}
fi
