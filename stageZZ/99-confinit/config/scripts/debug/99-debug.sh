#!/bin/bash

sync

{
    echo "---"
    date 
    echo "# dmesg"
    dmesg
    echo "# journalctl"
    journalctl -b -ax
    echo "# ip addr show"
    ip addr show
    echo "# systemctl status systemd-networkd"
    systemctl status systemd-networkd
    echo "# networkctl -a"
    networkctl -a
    echo "# networkctl status"
    networkctl status
    echo "# systemctl status"
    systemctl status
} > /etc/log.txt

sync

