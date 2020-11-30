#!/bin/bash

read -p "Enter the wireguard interface [wg0]: " wg_interface
wg_interface=${wg_interface:-wg0}

read -p "Enter the primary interface [eth0]: " primary_interface
primary_interface=${primary_interface:-eth0}

read -p "Enter the wireguard port number [51820]: " port_number
port_number=${port_number:-51820}

read -p "Enter the server address or ip [wg.example.com]: " server_address
server_address=${server_address:-'wg.example.com'}

read -p "Enter the server ip range [192.168.99.0/24]: " ip_range
ip_range=${ip_range:-'192.168.99.0/24'}

read -p "Use existing public and private key? Y/N [N]: " use_existing_keys
use_existing_keys=${use_existing_keys:-N}

if [[ ${use_existing_keys,,} != 'n' ]] ; then
	read -p "Private key: " private_key
	read -p "Public key: " public_key
	echo $private_key > ${wg_interface}.key.private
	echo $public_key > ${wg_interface}.key.public
else
	wg genkey | tee ${wg_interface}.key.private | wg pubkey > ${wg_interface}.key.public
	private_key=$(cat ${wg_interface}.key.private)
	public_key=$(cat ${wg_interface}.key.public)
fi

cat <<EOF > wg.def
_INTERFACE=${wg_interface}
_PRIMARY_INTERFACE=${primary_interface}
_VPN_NET=${ip_range}
_SERVER_PORT=${port_number}
_SERVER_LISTEN=${server_address}:\$_SERVER_PORT
_SERVER_PUBLIC_KEY=${public_key}
_SERVER_PRIVATE_KEY=${private_key}
EOF

if [[ ! -f server.conf.whitelist ]] ; then
    touch server.conf.whitelist
fi

if [[ ! -f server.conf.blacklist ]] ; then
    touch server.conf.blacklist
fi

if [[ ! -f server.conf.ports.whitelist ]] ; then
    touch server.conf.ports.whitelist
fi

if [[ ! -f /etc/wireguard/${wg_interface}.conf ]] ; then
    wg-quick up $wg_interface
    sudo ./config.sh -r
fi
