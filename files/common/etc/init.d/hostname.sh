#!/bin/bash
### BEGIN INIT INFO
# Provides:          hostname
# Required-Start:
# Required-Stop:
# Default-Start:     S
# Default-Stop:
# Short-Description: Set hostname based on BSP version
### END INIT INFO

. /etc/exorint.funcs

if [ ! -r /etc/hostname ]; then
    hn="$(exorint_hostname)"
    if [ $? -ne 0 ]; then
        hostname usom
    else
        hostname ${hn}
    fi
    hostname > /etc/hostname
else
    hostname -F /etc/hostname
fi
