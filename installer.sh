#!/bin/sh
#script by Abi Darwish

if [ $(uname -a | cut -d' ' -f2) != "QWRT" ]; then
	echo "Only QWRT is supported"
	exit 1
fi

if [ $(cat /tmp/sysinfo/model) != "Arcadyan AW1000" ]; then
        echo "Only Arcadyan AW1000 is supported"
	exit 1
fi

if [ ! -e /etc/arca ]; then
	mkdir -p /etc/arca
fi

if [ ! -e /usr/lib/rooter/connect/create_connect.sh.bak ]; then
	cp /usr/lib/rooter/connect/create_connect.sh /usr/lib/rooter/connect/create_connect.sh.bak
fi

sed -i '/^.*pgrep -f restart_wan/d;/^$/d' /usr/lib/rooter/connect/create_connect.sh

sed -i '/^.*pgrep -f \/etc\/arca\/restart_wan/d;/^$/d' /usr/lib/rooter/connect/create_connect.sh

sed -i '/#!\/bin\/sh/a\\nkill -9 \$\(pgrep -f restart_wan)' /usr/lib/rooter/connect/create_connect.sh

sed -i '/#!\/bin\/sh/a\\nkill -9 \$\(pgrep -f \/etc\/arca\/restart_wan)' /usr/lib/rooter/connect/create_connect.sh

sed -i '/if \[ -e \/etc\/arca\/restart_wan \].*$/,/fi/d' /usr/lib/rooter/connect/create_connect.sh

echo -e "	if [ -e /etc/arca/restart_wan ]; then
		/etc/arca/restart_wan &
	fi" >>/usr/lib/rooter/connect/create_connect.sh

cat << 'EOF' >/etc/arca/change_ip
#!/bin/sh
#script by Abi Darwish

[ $(pgrep -f /etc/arca/change_ip | wc -l) -gt 2 ] && exit 0

log() {
        modlog "$@"
}

n=0
>/tmp/wan_status
while true; do
        if ping -q -c 3 -W 1 -6 2606:4700:4700::1111 >/dev/null 2>&1; then
                echo -e "$(date) \t Internet is fine" | tee -a /tmp/wan_status
        else
                if ping -q -c 3 -W 1 1.1.1.1 >/dev/null; then
                        echo -e "$(date) \t Internet is fine" | tee -a /tmp/wan_status
                else
                        /usr/lib/rooter/gcom/gcom-locked /dev/ttyUSB2 run-at.gcom 1 "AT+CFUN=0" >/dev/null 2>&1 && /usr/lib/rooter/gcom/gcom-locked /dev/ttyUSB2 run-at.gcom 1 "AT+CFUN=1" >/dev/null 2>&1
                        sleep 10
                        WAN_IP=$(curl -s ipinfo.io/ip)
                        if [ -n ${WAN_IP} ]; then
                        	log "Disconnected. WAN IP changed to ${WAN_IP}"
                        	>/etc/arca/counter
                        else
                        	n=$(( $n + 1 ))
                        	echo "$n" >/etc/arca/counter
                        	if [ $(cat /etc/arca/counter) -ge 3 ]; then
                        		log "Disconnected. Check your sim card"
                        		>/etc/arca/counter
                        		exit 0
                        	fi
                        	if [ $(cat /etc/arca/counter) -eq 2 ]; then
					log "Restart module"
					/us/lib/rooter/gcom/gcom-locked/dev/ttyUSB2 run-at.gcom 1 "AT+CFUN=1,1"
				fi
                        fi
                fi
        fi
        sleep 30
done
EOF

if [ $(pgrep -f /etc/arca/change_ip | wc -l) -ge 1 ]; then
	kill -9 $(pgrep -f /etc/arca/change_ip)
fi

chmod 755 /etc/arca/change_ip
/etc/arca/change_ip &
exit 0
