#!/bin/bash

PRESERVEDPATH=$1
[ -z $PRESERVEDPATH ] && exit 1

function copy_to_dir ()
{
    mkdir -p $2
    cp $1 $2
}

mount -o remount,rw /mnt/factory

copy_to_dir $PRESERVEDPATH/etc/pointercal.xinput /mnt/factory/etc
copy_to_dir $PRESERVEDPATH/etc/rotation /mnt/factory/etc
copy_to_dir $PRESERVEDPATH/etc/X11/xorg.conf.d/x11-rotate.conf /mnt/factory/etc/X11/xorg.conf.d

mount -o remount,ro /mnt/factory

exit 0
