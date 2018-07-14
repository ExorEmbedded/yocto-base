#!/bin/sh

PRESERVEDPATH=$1
[ -z $PRESERVEDPATH ] && exit 1

SYSPARAMSCMD="/usr/bin/sys_params"

# applicable only if wifi0 autostart was enabled on previous BSP (System Settings implementation)
iw dev | grep -q "Interface wifi0" || exit 0
grep -q '"enabled": true' /etc/jmuconfig/network.json || exit 0

# enable with new implementation (EPAD System Parameters)
${SYSPARAMSCMD} -w network/wifi/nic/wifi0/autostart "true"

CHOSEN="/tmp/post.sh-chosen"
grep -A 6 '"chosen":' /etc/jmuconfig/network.json > $CHOSEN

${SYSPARAMSCMD} -w network/wifi/nic/wifi0/net/ssid "`grep '"ssid":' $CHOSEN | cut -d '"' -f 4`"
${SYSPARAMSCMD} -w network/wifi/nic/wifi0/net/bssid "`grep '"bssid":' $CHOSEN | cut -d '"' -f 4`"
${SYSPARAMSCMD} -w network/wifi/nic/wifi0/net/security "`grep '"security":' $CHOSEN | cut -d '"' -f 4`"
${SYSPARAMSCMD} -w network/wifi/nic/wifi0/net/psk "`grep '"psk":' $CHOSEN | cut -d '"' -f 4`"

dbus-send --print-reply --system --dest=com.exor.EPAD "/ServiceManager" com.exor.EPAD.ServiceManager.command string:"wifi" string:"apply" string:""

cp /etc/EPAD/system.ini $PRESERVEDPATH/etc/EPAD/
rm /etc/jmuconfig/network.json
sync
