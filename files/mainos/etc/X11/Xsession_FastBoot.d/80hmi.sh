#!/bin/sh

ln -s /dev/input/event1 			/dev/input/beeper
ln -s /dev/input/event0 			/dev/input/touchscreen0
ln -s /dev/rtc0         			/dev/rtc
ln -s /proc/self/fd/2   			/dev/stderr
ln -s /proc/self/fd/1   			/dev/stdout
ln -s /proc/self/fd/0   			/dev/stdin
ln -s /proc/self/fd     			/dev/fd
ln -s /sys/bus/spi/devices/spi1.0/eeprom 	/dev/fram

# Source defaults.
. /etc/default/rcS


#ONLY for debug
#XEYES=y

if [ $XEYES == "y" ]
then
    DISPLAY=:0 xeyes
else

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
		DISPLAY=:0 dbus-send --system --print-reply --dest=com.exor.JMLauncher '/' com.exor.JMLauncher.launchDesktop
	else
		if [ ! -z "$FASTBOOT" ] ; then
	        echo "HMI: KIOSK - FASTBOOT" | logger
            cd /mnt/data/hmi/$FASTBOOT
            ./run.sh &
            sleep 20;
        else
			echo "HMI: KIOSK" | logger
			# starts the desktop
			DISPLAY=:0 dbus-send --system --print-reply --dest=com.exor.JMLauncher '/' com.exor.JMLauncher.launchHMI | logger
		fi
	fi
fi
