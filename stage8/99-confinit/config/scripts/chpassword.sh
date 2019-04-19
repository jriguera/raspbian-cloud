#!/usr/bin/env bash

{{ if .Data.system.user }}
echo -n "Changing password for ${user} ... "
echo "{{ .Data.system.user.name }}:{{ .Data.system.user.password }}" | chpasswd
echo "done"
{{ end }}
exit 0
