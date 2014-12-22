#!/bin/bash

SCRIPT=autoexec.sh

echo > /tmp/autorun

autorun() {
    # wait until the system has boot (no rc scripts running up to 30 seconds)
    for i in `seq 1 20` ; do
        XX="`ps aux`" ; if  ! ( echo $XX | grep "rc " ) ; then 
		echo "AUTORUN BREAK" >> /tmp/autorun
		break;
	else
		sleep 1
		echo "Waiting system boot complete before starting autorun.sh script $1 ..." | logger -t "AUTORUN"
	fi
    done

    FILE=/mnt/${1}/${SCRIPT}

    if [ -f ${FILE} ]; then
        /bin/bash ${FILE}
    fi
}

autorun $@ &
