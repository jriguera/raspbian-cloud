#!/usr/bin/env bash

{{ if .Data.docker }}
{{ if .Data.docker.Portainer }}
{{ if .Data.docker.Portainer.apps }}
# see /etc/docker-compose/docker-compose.yml
mkdir -p /data/portainer
nohup curl --silent --retry-max-time 600 --max-time 30 --retry 10 --retry-delay 0 --location {{ .Data.docker.Portainer.apps }} -o /etc/portainer/apps.json &
{{ end }}
{{ end }}
{{ end }}

exit 0
