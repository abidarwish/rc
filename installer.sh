#!/bin/sh
#script by Abi Darwish

rm -rf installer.sh

#Cleanup from previous beta installation
rm -rf /etc/arca/restart_wan
sed -i '/^.*pgrep -f restart_wan/d;/^$/d' /usr/lib/rooter/connect/create_connect.sh
sed -i '/^.*pgrep -f \/etc\/arca\/restart_wan/d;/^$/d' /usr/lib/rooter/connect/create_connect.sh
sed -i '/if \[ -e \/etc\/arca\/restart_wan \].*$/,/fi/d' /usr/lib/rooter/connect/create_connect.sh

if [ $(uname -a | cut -d' ' -f2) != "QWRT" ]; then
        echo "Only QWRT is supported"
        exit 1
fi

if [ "$(cat /tmp/sysinfo/model)" != "Arcadyan AW1000" ]; then
        echo "Only Arcadyan AW1000 is supported"
        exit 1
fi

if [ ! -e /etc/arca ]; then
        mkdir -p /etc/arca
fi

if [ ! -e /usr/lib/rooter/connect/create_connect.sh.bak ]; then
        cp /usr/lib/rooter/connect/create_connect.sh /usr/lib/rooter/connect/create_connect.sh.bak
fi

sed -i '/^.*pgrep -f change_ip/d;/^$/d' /usr/lib/rooter/connect/create_connect.sh
sed -i '/^.*pgrep -f \/etc\/arca\/change_ip/d;/^$/d' /usr/lib/rooter/connect/create_connect.sh
sed -i '/#!\/bin\/sh/a\\nkill -9 \$\(pgrep -f change_ip)' /usr/lib/rooter/connect/create_connect.sh
sed -i '/#!\/bin\/sh/a\\nkill -9 \$\(pgrep -f \/etc\/arca\/change_ip)' /usr/lib/rooter/connect/create_connect.sh
sed -i '/if \[ -e \/etc\/arca\/change_ip \].*$/,/fi/d' /usr/lib/rooter/connect/create_connect.sh

if [ ! -e /usr/lib/rooter/connect/conmon.sh.bak ]; then
        cp /usr/lib/rooter/connect/conmon.sh /usr/lib/rooter/connect/conmon.sh.bak
fi

echo -e "#!/bin/sh
#script by Abi Darwish

if [ -e /etc/arca/change_ip ]; then
        /etc/arca/change_ip &
fi" >/usr/lib/rooter/connect/conmon.sh

cat << 'EOF' >/etc/arca/change_ip
#!/bin/sh
#script by Abi Darwish

[ $(pgrep -f /etc/arca/change_ip | wc -l) -gt 2 ] && exit 0

QMIChangeWANIP() {
        /usr/lib/rooter/gcom/gcom-locked /dev/ttyUSB2 run-at.gcom 1 AT+CFUN=0 >/dev/null 2>&1 && /usr/lib/rooter/gcom/gcom-locked /dev/ttyUSB2 run-at.gcom 1 AT+CFUN=1 /dev/null 2>&1
}

MBIMChangeWANIP() {
        /usr/lib/rooter/gcom/gcom-locked /dev/ttyUSB2 run-at.gcom 1 AT+CFUN=0 >/dev/null 2>&1 && /usr/lib/rooter/gcom/gcom-locked /dev/ttyUSB2 run-at.gcom 1 AT+CFUN=1 /dev/null 2>&1 && ifup wan && ifup wan1
}

log() {
        modlog "$@"
}

log "Start RC script"

n=0
>/tmp/wan_status
>/etc/arca/counter
while true; do
        if [ $(curl -I -s -o /dev/null -w "%{http_code}" https://www.youtube.com) -eq 200 ] && [ $(curl -I -s -o /dev/null -w "%{http_code}" https://fast.com) -eq 200 ]; then
                echo -e "$(date) \t Internet is fine" | tee -a /tmp/wan_status
        else
                log "Modem disconnected"
                if [ $(uci get modem.modem1.proto) -eq 88 ]; then
                        QMIChangeWANIP
                        log "QMI Protocol restarted"
                else
                        MBIMChangeWANIP
                        log "MBIM Protocol restarted"
                fi
                sleep 10
                WAN_IP=$(curl -s ipinfo.io/ip)
                if [ ! -z ${WAN_IP} ]; then
                        log "WAN IP changed to ${WAN_IP}"
                        >/etc/arca/counter
                else
                        n=$(( $n + 1 ))
                        echo "$n" >/etc/arca/counter
                        if [ $(cat /etc/arca/counter) -eq 2 ]; then
                                /usr/lib/rooter/gcom/gcom-locked/dev/ttyUSB2 run-at.gcom 1 "AT+CFUN=1,1"
                                log "Modem module restarted"
                        elif [ $(cat /etc/arca/counter) -ge 3 ]; then
                                log "Modem disconnected. Check your SIM card"
                                >/etc/arca/counter
                                exit 1
                        fi
                fi
        fi
        sleep 30
done
EOF

if [ ! -z $(pgrep -f /etc/arca/change_ip) ]; then
        kill -9 $(pgrep -f /etc/arca/change_ip)
fi

chmod 755 /etc/arca/change_ip
/etc/arca/change_ip &
echo "Done. You can close this terminal now"
exit 0
