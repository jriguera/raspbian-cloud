#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]
then
  echo "$(basename $0): Error, source and destination directories not specified"
  echo "Usage $(basename $0) <src-folder> <dst-folder> [<ownership-permissions-metadata>]"
  echo "Utility to copy all files from <src-folder> to <dst-folder>"
  exit 1
fi
SRC="${1%/}"
DST="${2%/}"
META="${3:-$SRC.metadata}"

# Copy output to logger
exec 1> >(tee >(logger -t $(basename $0))) 2>&1

# Exit if no src
if [ -z "${SRC}" ] || [ -z "${DST}" ]
then
  echo "$(basename $0): Error, empty folder!"
  exit 1
fi

if [ -d "${SRC}" ]
then
  echo "* Copying files from ${SRC} to ${DST}: "
  cp -d -v -R "${SRC}/." "${DST}/"

  if [ -s "${META}" ]
  then
    echo "* Changing ownership and permission as in ${META} on ${DST}: "
    while read -r line
    do
      [ -z "$line" ] && continue
      [[ "$line" =~ ^#.*$ ]] && continue
      echo "- ${line}"
      read -r f p ug <<< "${line}"
      chown -v -R "${ug}" "${DST}/${f}" || true
      chmod -v -R "${p}" "${DST}/${f}" || true
    done < "${META}"
  else
    echo "* Metadata file ${META} not found. Ignoring permissions metadata"
  fi
  echo "* Done $$"
  exit 0
else
  echo "* Input folder ${SRC} not found!"
  exit 1
fi
