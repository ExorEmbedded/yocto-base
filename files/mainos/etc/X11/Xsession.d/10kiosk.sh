#!/bin/sh

echo "HMI: booting!" | logger

export TMPDIR=/mnt/.psplash/
# Source defaults.
. /etc/default/rcS

if [ ! -z "$FASTBOOT" ] && [ -d "/mnt/data/hmi/$FASTBOOT/deploy" ] ; then
	LD_LIBRARY_PATH=/mnt/data/hmi/$FASTBOOT/deploy EPAD &
else
    # starts EPAD service
    dbus-send --system --dest=com.exor.EPAD '/' com.exor.EPAD.ping
fi

if [[ -e $TMPDIR/taptap ]] ; then
	while ( (cat $TMPDIR/taptap | grep wait) > /dev/null 2>&1 ) ; do
		echo "HMI: waiting tapttap" | logger
		ping -c 1 -i 0.3 127.0.0.1 > /dev/null 2>&1;
	done

	if [[ -e $TMPDIR/taptap ]] ; then
		echo "HMI: tap tap content: $(cat $TMPDIR/taptap)" | logger
		if ( (cat $TMPDIR/taptap | grep disable-kiosk-tchcalibrate) > /dev/null 2>&1 ) ; then
			# force pointer calibration
			rm /etc/pointercal.xinput
			echo "HMI: force pointer calibration" | logger
		fi

		if ( (cat $TMPDIR/taptap | grep disable-kiosk) > /dev/null 2>&1 ) ; then
			# start no-kiosk mode
			echo "HMI: nokiosk mode" | logger
			touch /etc/nokiosk
		fi
	fi 
fi


