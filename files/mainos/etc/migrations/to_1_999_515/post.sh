#!/bin/sh

PRESERVEDPATH=$1
[ -z $PRESERVEDPATH ] && exit 1

SYSPARAMSCMD="/usr/bin/sys_params"

# modules not loaded yet - detect presence of wifi based on presence of script
[ -e /etc/init.d/networking_kmod-wifi-rs9113.sh ] || exit 0

# applicable only if wifi0 autostart was enabled on previous BSP (System Settings implementation)
grep -q '"enabled": true' $PRESERVEDPATH/etc/jmuconfig/network.json || exit 0

# enable with new implementation (EPAD System Parameters)
$SYSPARAMSCMD -w network/wifi/nic/wifi0/autostart "true"
$SYSPARAMSCMD -w network/wifi/autostartNics "wifi0"

CHOSEN="/tmp/post.sh-chosen"
grep -A 6 '"chosen":' $PRESERVEDPATH/etc/jmuconfig/network.json > $CHOSEN

$SYSPARAMSCMD -w network/wifi/nic/wifi0/net/ssid "`grep '"ssid":' $CHOSEN | cut -d '"' -f 4`"
$SYSPARAMSCMD -w network/wifi/nic/wifi0/net/bssid "`grep '"bssid":' $CHOSEN | cut -d '"' -f 4`"
$SYSPARAMSCMD -w network/wifi/nic/wifi0/net/security "`grep '"security":' $CHOSEN | cut -d '"' -f 4`"
$SYSPARAMSCMD -w network/wifi/nic/wifi0/net/psk "`grep '"psk":' $CHOSEN | cut -d '"' -f 4`"

cp /etc/EPAD/system.ini $PRESERVEDPATH/etc/EPAD/
rm $PRESERVEDPATH/etc/jmuconfig/network.json
sync
