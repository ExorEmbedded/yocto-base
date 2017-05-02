#!/bin/sh

ln -s /dev/rtc0         			/dev/rtc
ln -s /proc/self/fd/2   			/dev/stderr
ln -s /proc/self/fd/1   			/dev/stdout
ln -s /proc/self/fd/0   			/dev/stdin
ln -s /proc/self/fd     			/dev/fd

# Source defaults.
. /etc/default/rcS

# Fast parse of jmlauncher.xml
if [ ! -z "$FASTBOOT" ] && [ -e "/mnt/data/hmi/jmlauncher.xml" ]
then
    apps_to_launch=$(grep autostart /mnt/data/hmi/jmlauncher.xml | grep -c 1)
    if [ "$apps_to_launch" = "1" ]
    then
        app_to_launch_name=$(grep autostart /mnt/data/hmi/jmlauncher.xml -C 2 | grep installationFolder | awk -F '[<>]' '{print $3}');
        if [ "$app_to_launch_name" != "$FASTBOOT" ]
        then
            #Change FASTBOOT
            sed -i "s/^\(FASTBOOT\s*=\s*\).*\$/\1$app_to_launch_name;/" /etc/default/rcS
            #Faster then command: source /etc/default/rcS
            FASTBOOT=$app_to_launch_name;
        fi
    fi
else
    apps_to_launch=0;
fi

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
    if [ ! -z "$FASTBOOT" ] && [ -e "/mnt/data/hmi/$FASTBOOT/run.sh" ] && [ "$apps_to_launch" -eq "1" ]; then
        echo "HMI: KIOSK - FASTBOOT" | logger
        cd /mnt/data/hmi/"$FASTBOOT" || return
        ./run.sh &
        sleep 20;
    else
        echo "HMI: KIOSK" | logger
        # starts the desktop
        DISPLAY=:0 dbus-send --system --print-reply --dest=com.exor.JMLauncher '/' com.exor.JMLauncher.launchHMI | logger
    fi
fi

