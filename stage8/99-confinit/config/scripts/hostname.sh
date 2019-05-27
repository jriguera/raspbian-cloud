#!/usr/bin/env bash

{{ if .Data.system.hostname }}
echo "{{ .Data.system.hostname }}{{ if .Data.system.domain }}.{{ .Data.system.domain }}{{ end }}" > /etc/hostname
hostnamectl set-hostname {{ .Data.system.hostname }}{{ if .Data.system.domain }}.{{ .Data.system.domain }}{{ end }} || true
{{ else }}
exit 0
{{ end }}
