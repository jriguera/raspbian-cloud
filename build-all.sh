#!/bin/bash -e

echo "Checking git submodules ..."
git submodule init
git submodule update

echo "Building traditional RPI image ..."
./raspbian-cloud-build.sh

echo "Building Mender OTA image ..."
./mender-ota-build.sh

echo "All done! Have a look in deploy folder:"
ls -l deploy
