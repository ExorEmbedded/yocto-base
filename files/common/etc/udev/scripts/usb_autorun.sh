#!/bin/bash

SCRIPT=autoexec.sh

# consistency check: avoid running multiple scripts in parallel
[ "`ps ax | grep $0 | grep $1\$ | wc -l `" != "2" ] && exit

# consistecy check : are we executing the script from the deviced signalled by kernel?
cat /proc/mounts | grep "$DEVNAME " | grep "/mnt/$1 " || exit

echo > /tmp/autorun

autorun() {
    # wait until the system has boot (no rc scripts running up to 30 seconds)
    for i in `seq 1 20` ; do
        XX="`ps aux`" ; if  ! ( echo $XX | grep "/rc " ) ; then
		echo "AUTORUN BREAK" >> /tmp/autorun
		break;
	else
		sleep 1
		echo "Waiting system boot complete before starting autorun.sh script $1 ..." | logger -t "AUTORUN"
	fi
    done

    if [ -e /mnt/${1}/resetnetworksettings ]; then
        echo "Network reset requested - fowarding to EPAD" | logger -t "AUTORUN"
        dbus-send --print-reply --system --dest=com.exor.EPAD "/NetworkManager" com.exor.EPAD.NetworkManager.resetConfiguration

        # continuous beep to force user to remove key and reboot
        dbus-send --system --print-reply --dest=com.exor.EPAD "/Buzzer" com.exor.EPAD.Buzzer.beep int32:440 int32:-1
    fi

    # exit if autoexec is locked by factory setting
    [ "$(/usr/bin/sys_params -r factory/services/autorun/mode)" = "locked" ] && exit

    FILE=/mnt/${1}/${SCRIPT}

    if [ -f ${FILE} ]; then
        /bin/bash ${FILE}
    fi
}

autorun $@ &
