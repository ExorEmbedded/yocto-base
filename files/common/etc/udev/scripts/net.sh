#! /bin/bash

[ -z "$IFACE" -o ! -e /run/dbus/system_bus_socket ] && exit 0

if ( !( cat /etc/network/interfaces | grep -q " $IFACE " ) || ! ( /usr/sbin/ifplugd -c -i $IFACE &>/dev/null ) ); then
	/usr/bin/dbus-send --print-reply --system --dest=com.exor.EPAD "/NetworkManager" com.exor.EPAD.NetworkManager.updateInterfaces
fi
