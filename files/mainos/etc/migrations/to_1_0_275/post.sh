#!/bin/sh

PRESERVEDPATH=$1
[ -z $PRESERVEDPATH ] && exit 1

SYSPARAMSCMD="/usr/bin/sys_params"

# Force no behaviour on inputs because previous default was broken [#929]
MIGRATED=0
if ${SYSPARAMSCMD} -r hwplugin/plcm09/sensors/0/mode 2>/dev/null; then
    MIGRATED=1
    ${SYSPARAMSCMD} -w hwplugin/plcm09/sensors/0/mode 0
fi

if ${SYSPARAMSCMD} -r hwplugin/plcm09/sensors/1/mode 2>/dev/null; then
    MIGRATED=1
    ${SYSPARAMSCMD} -w hwplugin/plcm09/sensors/1/mode 0
fi

if [ $MIGRATED -eq 1 ]; then
    cp /etc/EPAD/system.ini $PRESERVEDPATH/etc/EPAD/
    sync
fi
