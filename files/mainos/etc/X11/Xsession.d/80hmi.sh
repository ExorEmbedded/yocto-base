#!/bin/sh


if [[ -e /mnt/data ]] ; then
	# prepare foldef for jmlauncher
	if [[ ! -e /mnt/data/hmi ]] ; then
		mkdir /mnt/data/hmi 2> /dev/null
	fi
fi

if [[ ! -e /etc/jmlauncher/ ]] ; then
	mkdir /etc/jmlauncher
fi


if [[ -e /etc/nokiosk ]] ; then
	echo "HMI: NOKIOSK" | logger
	# starts the HMI
	rm /etc/nokiosk # next boot will reset to default kiosk mode
	DISPLAY=:0 dbus-send --session --print-reply --dest=com.exor.JMLauncher '/' com.exor.JMLauncher.launchDesktop
else
	echo "HMI: KIOSK" | logger
	# starts the desktop
	DISPLAY=:0 dbus-send --session --print-reply --dest=com.exor.JMLauncher '/' com.exor.JMLauncher.launchHMI | logger
fi
