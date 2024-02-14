#!/bin/sh
#script by Abi Darwish

if [ -n $(pgrep -f change_ip); then
	kill -9 $(pgrep -f change_ip)
fi
if [ -n $(pgrep -f /etc/arca/change_ip) ]; then
	kill -9 $(pgrep -f /etc/arca/change_ip)
fi

sed -i '/^.*pgrep -f change_ip/d;/^$/d' /usr/lib/rooter/connect/create_connect.sh
sed -i '/^.*pgrep -f \/etc\/arca\/change_ip/d;/^$/d' /usr/lib/rooter/connect/create_connect.sh
sed -i '/if \[ -e \/etc\/arca\/change_ip \].*$/,/fi/d' /usr/lib/rooter/connect/create_connect.sh

rm -rf /etc/arca/change_ip
