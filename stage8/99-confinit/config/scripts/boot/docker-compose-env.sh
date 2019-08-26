#!/usr/bin/env bash

sed -ie 's/^\(.*\)=\(.*\)$/\U\1\E=\2/g' /etc/docker-compose/.env
