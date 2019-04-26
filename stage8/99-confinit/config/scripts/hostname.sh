#!/usr/bin/env bash

{{ if .Data.system.hostname }}
hostnamectl set-hostname {{ .Data.system.hostname }}{{ if .Data.system.domain }}.{{ .Data.system.domain }}{{ end }}
{{ else }}
exit 0
{{ end }}
