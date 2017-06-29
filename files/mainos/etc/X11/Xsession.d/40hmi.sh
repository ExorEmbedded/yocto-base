#!/bin/sh

ln -s /dev/rtc0         			/dev/rtc
ln -s /proc/self/fd/2   			/dev/stderr
ln -s /proc/self/fd/1   			/dev/stdout
ln -s /proc/self/fd/0   			/dev/stdin
ln -s /proc/self/fd     			/dev/fd

# Source defaults.
. /etc/default/rcS

#Run a simple splash in x for reduce black screen --> #722
if [ ! -z "$FASTBOOT" ] && [ -x /usr/bin/xsplash ]; then
    DISPLAY=:0 /usr/bin/xsplash &
fi;

JMLAUNCHER_FILE="/mnt/data/hmi/jmlauncher.xml"

# Fast parse of jmlauncher.xml
if [ ! -z "$FASTBOOT" ] && [ -e $JMLAUNCHER_FILE ] && [ ! -e /etc/nokiosk ]
then
    apps_to_launch=$(grep autostart $JMLAUNCHER_FILE | grep -c 1)
    if [ "$apps_to_launch" = "1" ]
    then
        active_app=$(grep autostart $JMLAUNCHER_FILE | grep 1);
        app_to_launch_name=$(grep $active_app $JMLAUNCHER_FILE -C 2 | grep installationFolder | awk -F '[<>]' '{print $3}');
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
        ( ./run.sh -kiosk |& logger ) & # ticket 682
        sleep 20;
    else
        echo "HMI: KIOSK" | logger
        # starts the desktop
        DISPLAY=:0 dbus-send --system --print-reply --dest=com.exor.JMLauncher '/' com.exor.JMLauncher.launchHMI | logger
    fi
fi

