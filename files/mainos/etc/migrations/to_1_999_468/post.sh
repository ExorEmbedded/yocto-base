#!/bin/sh

PRESERVEDPATH=$1
[ -z $PRESERVEDPATH ] && exit 1

SCREENSAVER_CONF="$PRESERVEDPATH/etc/X11/app-defaults/XScreenSaver"

[ ! -e "${SCREENSAVER_CONF}" ] && exit 0

sed -i 's/^mode: off/mode: blank/' "${SCREENSAVER_CONF}"
