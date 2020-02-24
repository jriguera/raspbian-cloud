#!/bin/bash -e

VERSION="1.0"
URL="https://github.com/jriguera/debian-packages/releases/download/python2python3-${VERSION}/python2python3_${VERSION}_all.deb"

on_chroot << EOF
wget "${URL}" -nv -O /tmp/python2python3.deb
dpkg -i /tmp/python2python3.deb
rm -f /tmp/python2python3.deb

apt-get -y purge python python-minimal python2 python2-minimal python2.7 python2.7-minimal libpython2.7-stdlib libpython2.7-minimal
apt-get -y autoremove
EOF
