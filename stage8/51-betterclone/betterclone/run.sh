#!/usr/bin/env bash

export PREFIX="$(pwd)"
sudo PREFIX="${PREFIX}" "${PREFIX}/bin/betterclone" "${@}"

