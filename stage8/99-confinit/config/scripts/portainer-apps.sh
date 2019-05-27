#!/usr/bin/env bash

{{ if .Data.docker }}
{{ if .Data.docker.portainer }}
{{ if .Data.docker.portainer.apps }}
# see /etc/docker-compose/docker-compose.yml
mkdir -p /data/portainer
nohup curl --retry-max-time 600 --max-time 30 --retry 10 --retry-delay 0 \
     -L {{ .Data.docker.portainer.apps }} \
     -o /data/portainer/apps.json \
</dev/null >/tmp/run/$(basename -- "$0").log  2>&1 &
{{ end }}
{{ end }}
{{ end }}

exit 0
