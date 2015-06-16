#!/bin/sh

JMUCONFIG_TESTURL="localhost:3000/api/v1/system"
JMUCONFIG_MAINURL="http://localhost:8080"
BROWSER_FLAGS="-f -l -g -c"

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

    DISPLAY=:0 su - user -c "WebkitBrowser $JMUCONFIG_MAINURL $BROWSER_FLAGS 2>&1 | logger -t JMUConfig-app"

} &
