#!/bin/sh

if [ "$USER" = "admin" ]; then
    PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
fi

umask 002
