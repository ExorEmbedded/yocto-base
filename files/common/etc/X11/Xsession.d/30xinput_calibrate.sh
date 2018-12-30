#!/bin/sh

. /etc/formfactor/config

xsplash QUIT

if [ "$HAVE_TOUCHSCREEN" = "1" ]; then
	/usr/bin/xinput_calibrator_once.sh
fi
