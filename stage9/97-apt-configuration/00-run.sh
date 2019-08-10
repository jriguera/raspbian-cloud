#!/bin/bash -e

on_chroot << EOF
# Disable daily apt unattended updates.
echo 'APT::Periodic::Enable "0";' >> /etc/apt/apt.conf.d/10periodic
# Enable retries, which should reduce the number box buld failures resulting from a temporal network problems.
echo 'APT::Acquire::Retries "3";' > /etc/apt/apt.conf.d/80retries

EOF
