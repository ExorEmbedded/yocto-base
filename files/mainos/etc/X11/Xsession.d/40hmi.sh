#!/bin/sh

ln -s /dev/rtc0         			/dev/rtc
ln -s /proc/self/fd/2   			/dev/stderr
ln -s /proc/self/fd/1   			/dev/stdout
ln -s /proc/self/fd/0   			/dev/stdin
ln -s /proc/self/fd     			/dev/fd

# Source defaults.
. /etc/default/rcS
. /etc/exorint.funcs

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

if [ -e $TMPDIR/taptap ] || [ -z "$FASTBOOT" ] || [ $apps_to_launch -eq 0 ];
then
    # This simulate triple steps fast boot --> Superfast
    carrier=$(exorint_ver_carrier)
    if [ "$carrier" == "WU16" ]
    then
        /etc/init.d/ifplugd start
        /etc/init.d/dbus-1 start
        sleep 1;
    fi;
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

FASTBOOT_KIOSK=0

if [[ -e /etc/nokiosk ]] ; then
	echo "HMI: NOKIOSK" | logger
	# starts the HMI
	#rm /etc/nokiosk # next boot will reset to default kiosk mode
	mv /etc/nokiosk /var/run/
	dbus-send --system --print-reply --dest=com.exor.JMLauncher '/' com.exor.JMLauncher.launchDesktop
	dbus-send --system --print-reply --dest=com.exor.EPAD '/' com.exor.EPAD.updateCursorVisibility
else

    if [ ! -z "$FASTBOOT" ] && [ -e "/mnt/data/hmi/$FASTBOOT/run.sh" ] && [ "$apps_to_launch" -eq "1" ] && [ "$FASTBOOT" == "$app_to_launch_name" ]; then
        echo "HMI: KIOSK - FASTBOOT" | logger
        FASTBOOT_KIOSK=1

        # Without codesys JMobile is able to handle starting on a RO location.
        # In this case we can defer data partition fsck and RW remount to speed up the boot
        if [ "$FASTBOOT" != "qthmi"] || [ -e /mnt/data/hmi/codesys_auto -o -e /mnt/data/hmi/qthmi/codesys_auto ]; then
                DATAPARTITION=/dev/mmcblk1p6
                DATATMPMNT=/mnt/data

		if ( mount | grep $DATAPARTITION | grep -q -v rw, ); then
			[ "$ENABLE_ROOTFS_FSCK" = "yes" ] && exorint_extfsck $DATAPARTITION
			mount -o remount,rw $DATATMPMNT
			mount -o remount,rw /home
		fi
        fi

        cd /mnt/data/hmi/"$FASTBOOT" || return
        ( ./run.sh -kiosk |& logger ) & # ticket 682
    else
        echo "HMI: KIOSK" | logger

        dbus-send --system --print-reply --dest=com.exor.EPAD '/' com.exor.EPAD.updateCursorVisibility

        # starts the desktop
        dbus-send --system --print-reply --dest=com.exor.JMLauncher '/' com.exor.JMLauncher.launchHMI | logger
    fi

fi

# force xsplash quit only if overlay is used - otherwise other windows will be
# stacked on top and the process will die after RUN_TIME_MS (default 2 minutes)
# if we have us03 scenarios with excessive black we can consider improving this [#1004]
if [ -e /dev/fb1 ]; then
    sleep 2
    xsplash QUIT
fi

if [ $FASTBOOT_KIOSK -eq 1 ]; then
    dbus-send --system --print-reply --dest=com.exor.EPAD '/' com.exor.EPAD.updateCursorVisibility
    sleep 20
fi
