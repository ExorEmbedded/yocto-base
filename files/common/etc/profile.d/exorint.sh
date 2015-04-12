#!/bin/sh

if [ "$USER" = "admin" ]; then
    PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
fi

export PS1="`[ -e /boot/version ] && cat /boot/version` \u@\h:\w\$ "

umask 002
