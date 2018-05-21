#!/bin/sh

PRESERVEDPATH=$1
[ -z $PRESERVEDPATH ] && exit 1

( cat /boot/version | grep '^UN6[7|8]WU16' ) || exit 0

rm -rf "$PRESERVEDPATH/etc/rc5.d/S27dbus-1"
rm -rf "/etc/rc5.d/S27dbus-1"
