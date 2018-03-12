#!/bin/sh

PRESERVEDPATH=$1
[ -z $PRESERVEDPATH ] && exit 1

SCREENSAVER_CONF="$PRESERVEDPATH/etc/X11/app-defaults/XScreenSaver"

[ ! -e "${SCREENSAVER_CONF}" ] && exit 0

sed -i -e 's|^mode: off|mode: blank|' \
       -e  's|^programs: /usr/bin/xset dpms force off|programs: /usr/bin/xscreensaver-trigger|' \
       "${SCREENSAVER_CONF}"
