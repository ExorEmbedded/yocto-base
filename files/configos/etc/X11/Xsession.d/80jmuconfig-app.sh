#!/bin/sh

JMUCONFIG_TESTURL="localhost:3000/api/v1/system"

jmuconfig_wait()
{
    while true; do
        wget -O - "${JMUCONFIG_TESTURL}" >/dev/null 2>&1
        [ $? -eq 0 ] && break
        logger -t $0 "waiting for JMUConfig"
        sleep 1
    done
}

{
    jmuconfig_wait

    logger -t $0 "Running jmuconfig-app"

    DISPLAY=:0 su - user -c 'jmuconfig-app 2>&1 | logger -t JMUConfig-app'

    sync

    reboot -f

} &
