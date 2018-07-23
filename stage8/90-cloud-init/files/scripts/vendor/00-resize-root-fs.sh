#!/bin/sh

ROOT_DEV=$(findmnt / -o source -n)
logger -s "Running resize2f $ROOT_DEV ..."
resize2fs $ROOT_DEV

