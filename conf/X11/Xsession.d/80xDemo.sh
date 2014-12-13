#!/bin/sh

DISPLAY=:0 exec /usr/bin/xterm -e "/sbin/ifconfig ; /bin/sh" &
