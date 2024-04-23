#!/bin/sh
#script by Abi Darwish

if [ $(pgrep -f change_ip | wc -l) -ne 0 ]; then
	kill -9 $(pgrep -f change_ip)
fi
if [ $(pgrep -f /etc/arca/change_ip | wc -l) -ne 0 ]; then
	kill -9 $(pgrep -f /etc/arca/change_ip)
fi

sed -i '/^.*pgrep -f change_ip/d;/^$/d' /usr/lib/rooter/connect/create_connect.sh
sed -i '/^.*pgrep -f \/etc\/arca\/change_ip/d;/^$/d' /usr/lib/rooter/connect/create_connect.sh
sed -i '/if \[ -e \/etc\/arca\/change_ip \].*$/,/fi/d' /usr/lib/rooter/connect/create_connect.sh
sed -i '/\/etc\/arca\/counter/d' /etc/init.d/rooter

if [ -e /usr/lib/rooter/connect/conmon.sh.bak ]; then
        mv /usr/lib/rooter/connect/conmon.sh.bak /usr/lib/rooter/connect/conmon.sh
	chmod 755 /usr/lib/rooter/connect/conmon.sh
fi

rm -rf /etc/arca/change_ip
