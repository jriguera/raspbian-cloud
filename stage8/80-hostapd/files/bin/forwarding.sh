#!/usr/bin/env bash

PROGRAM=${PROGRAM:-$(basename "${BASH_SOURCE[0]}")}
PROGRAM_NAME="${PROGRAM%%.*}"
PROGRAM_IFACE="${PROGRAM_NAME##*-}"

# client network (running hostapd). interface is an env var
# set up by hostapd
DOWNSTREAM=${DOWSTREAM:-$interface}
# upstream network (internet)
UPSTREAM=${UPSTREAM:-$PROGRAM_IFACE}
# DHCP reason
REASON="${reason}"
# Sysctl ip_forward
SYSCTL_IP_FORWARD="${SYSCTL_IP_FORWARD:-1}"
SYSCTL_IP_FORWARD_STATE="/var/run/hostapd/ip_forward"


usage() {
    cat <<EOF
Usage:
    ${PROGRAM} [HELP | STATIC | BOUND | STOP | STOPPED]

Dhcpcd hook script to manage forwarding.
This script uses the environment variables provided by
dhcpcd in order to enable forwarding.
https://jlk.fjfi.cvut.cz/arch/manpages/man/dhcpcd-run-hooks.8.en

EOF
}


check() {
    if [ -z "${DOWNSTREAM}" ]
    then
        echo "${PROGRAM}: DOWNSTREAM (interface env variable) not defined!"
        return 1
    fi
    if [ -z "${UPSTREAM}" ]
    then
        echo "${PROGRAM}: UPSTREAM (from program name) to connect to internet not defined!"
        return 1
    fi
    if [ -z "${REASON}" ]
    then
        echo "${PROGRAM}: REASON (reason env variable) not defined!"
        return 1
    fi
    return 0
}


up() {
    if [ "x${SYSCTL_IP_FORWARD}" == "x1" ]
    then
        echo "${PROGRAM}: Turn on ip forwarding."
        mkdir -p "$(dirname ${SYSCTL_IP_FORWARD_STATE})"
        # save state
        cat /proc/sys/net/ipv4/ip_forward > "${SYSCTL_IP_FORWARD_STATE}"
        echo 1 > /proc/sys/net/ipv4/ip_forward
    fi
    if ! iptables --table nat --check POSTROUTING -o "${UPSTREAM}" --jump MASQUERADE  2>/dev/null
    then
        echo "${PROGRAM}: Setting up iptables rules to allow FORWARDING."
        # Allow IP Masquerading (NAT) of packets from clients (downstream) to upstream network (internet)
        iptables -t nat -A POSTROUTING -o $UPSTREAM -j MASQUERADE
        # Forward packets from downstream clients to the upstream internet
        iptables -A FORWARD -i $DOWNSTREAM -o $UPSTREAM -j ACCEPT
        # Forward packers from the internet to clients IF THE CONNECTION IS ALREADY OPEN!
        iptables -A FORWARD -i $UPSTREAM -o $DOWNSTREAM -m state --state RELATED,ESTABLISHED -j ACCEPT
        echo "${PROGRAM}: Done. Forwarding enabled: ${DOWNSTREAM} > ${UPSTREAM}"
    fi
}


down() {
    if [ "x${SYSCTL_IP_FORWARD}" == "x1" ]
    then
        if [ -r "${SYSCTL_IP_FORWARD_STATE}" ]
        then
            echo "${PROGRAM}: Re-establishing ip forwarding."
            cat "${SYSCTL_IP_FORWARD_STATE}" > /proc/sys/net/ipv4/ip_forward
        else
            echo "${PROGRAM}: Turn off ip forwarding."
            echo 0 > /proc/sys/net/ipv4/ip_forward
        fi
    fi
    if iptables --table nat --check POSTROUTING -o "${UPSTREAM}" --jump MASQUERADE  2>/dev/null
    then
        echo "${PROGRAM}: Deleting iptables rules to remove FORWARDING: ${DOWNSTREAM} > ${UPSTREAM}"
        # Allow IP Masquerading (NAT) of packets from clients (downstream) to upstream network (internet)
        iptables -t nat -D POSTROUTING -o $UPSTREAM -j MASQUERADE
        # Forward packets from downstream clients to the upstream internet
        iptables -D FORWARD -i $DOWNSTREAM -o $UPSTREAM -j ACCEPT
        # Forward packers from the internet to clients IF THE CONNECTION IS ALREADY OPEN!
        iptables -D FORWARD -i $UPSTREAM -o $DOWNSTREAM -m state --state RELATED,ESTABLISHED -j ACCEPT
        echo "${PROGRAM}: Done. Forwarding disabled."
    fi
}


if [ "$#" -ne 0 ]; then
    echo "${PROGRAM}: Illegal number of parameters!"
    usage
    exit 1
else
    case "${REASON}" in
    STATIC|BOUND)
        check && up || exit 1
    ;;
    STOP|STOPPED)
        check && down || exit 1
    ;;
    help|HELP)
        usage
    ;;
    *)
        echo "${PROGRAM}: Ignoring ${REASON}"
    ;;
    esac
    exit 0
fi

