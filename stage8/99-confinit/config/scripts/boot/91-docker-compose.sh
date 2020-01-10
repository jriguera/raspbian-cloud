#!/usr/bin/env bash

# Hack to capitalize env vars
sed -ie 's/^\(.*\)=\(.*\)$/\U\1\E=\2/g' /etc/docker-compose/.env

# Docker
{{ if .Data.docker.compose }}
echo -n "* Enable Docker Compose ... "
rm -f /etc/docker-compose/docker-compose-disabled
echo "done"
{{ else }}
echo -n "* Disable Docker Compose ... "
echo "Disabled by confinit, $(date)" > /etc/docker-compose/docker-compose-disabled
echo "done"
{{ end }}
