#!/bin/bash

SCRIPT=autoexec.sh

autorun() {
    FILE=/mnt/${1}/${SCRIPT}
    sleep 10

    if [ -f ${FILE} ]; then
        /bin/bash ${FILE}
    fi
}

autorun $@ &

