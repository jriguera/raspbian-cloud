#!/usr/bin/env bash

{{ if .Data.betterclone }}
systemctl enable "betterclone-restore@data.service"
systemctl enable "betterclone-backup@data.timer"
systemctl start "betterclone-restore@data.service"
systemctl start "betterclone-backup@data.timer"
{{ else }}
systemctl stop "betterclone-restore@data.service"
systemctl stop "betterclone-backup@data.timer"
systemctl disable "betterclone-restore@data.service"
systemctl disable "betterclone-backup@data.timer"
{{ end }}

exit 0
