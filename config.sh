#!/bin/bash

. ./wg.def
SERVER_TPL_FILE=server.conf.tpl
WG_TMP_CONF_FILE=.$_INTERFACE.conf
SAVED_FILE=.saved
WG_CONF_FILE="/etc/wireguard/$_INTERFACE.conf"

generate_and_install_server_config_file() {
    whitelist=$(paste -d, -s server.conf.whitelist)
    blacklist=$(paste -d, -s server.conf.blacklist)
    whitelist_ports=$(paste -d, -s server.conf.ports.whitelist)

    postup="iptables -A FORWARD -i %i -j ACCEPT;"
    postdown="iptables -D FORWARD -i %i -j ACCEPT;"

    if [ ! -z "$whitelist" ] ; then
        postup="${postup} iptables -A FORWARD -i %i -d ${whitelist} -j ACCEPT;"
        postdown="${postdown} iptables -D FORWARD -i %i -d ${whitelist} -j ACCEPT;"
    fi
    if [ ! -z "$blacklist" ] ; then
        postup="${postup} iptables -A FORWARD -i %i -d ${blacklist} -j DROP;"
        postdown="${postdown} iptables -D FORWARD -i %i -d ${blacklist} -j DROP;"
    fi

    if [ ! -z "$whitelist_ports" ] ; then
        postup="${postup} iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ${_PRIMARY_INTERFACE} -p tcp --match multiport --dport ${whitelist_ports} -j MASQUERADE; iptables -t nat -A POSTROUTING -o ${_PRIMARY_INTERFACE} -p udp --match multiport --dport ${whitelist_ports} -j MASQUERADE"
        postdown="${postdown} iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ${_PRIMARY_INTERFACE} -p tcp --match multiport --dport ${whitelist_ports} -j MASQUERADE; iptables -t nat -A POSTROUTING -o ${_PRIMARY_INTERFACE} -p udp --match multiport --dport ${whitelist_ports} -j MASQUERADE"
    else
        postup="${postup} iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ${_PRIMARY_INTERFACE} -j MASQUERADE"
        postdown="${postdown} iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ${_PRIMARY_INTERFACE} -j MASQUERADE"
    fi

    local template_file=${SERVER_TPL_FILE}
    local ip

    # server config file
    eval "echo \"$(cat "${template_file}")\"" > $WG_TMP_CONF_FILE
    while read user vpn_ip public_key; do
      ip=${vpn_ip%/*}/32
      cat >> $WG_TMP_CONF_FILE <<EOF
[Peer]
PublicKey = $public_key
AllowedIPs = $ip
EOF
    done < ${SAVED_FILE}
    \cp -f $WG_TMP_CONF_FILE $WG_CONF_FILE
}

do_clear() {
    local interface=$_INTERFACE
    wg-quick down $interface
    > $WG_CONF_FILE
    rm -f ${SAVED_FILE} ${AVAILABLE_IP_FILE}
}

restart_interface() {
    echo "Bringing down Wireguard interface $_INTERFACE"
    sudo wg-quick down $_INTERFACE
    generate_and_install_server_config_file
    echo "Starting Wireguard interface $_INTERFACE"
    sudo wg-quick up $_INTERFACE
}

usage() {
    echo "usage: $0 [-r|-d]"
    echo
    echo "       -r                       Reload wireguard interface"
    echo "       -d                              Clear configuration"
    echo

}


# main
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

action=$1

if [[ $action == "-r" ]]; then
    restart_interface
elif [[ $action == "-d" ]]; then
    do_clear
else
    usage
    exit 1
fi

