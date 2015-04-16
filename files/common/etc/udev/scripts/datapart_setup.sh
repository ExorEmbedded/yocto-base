#!/bin/bash
#
# Activate setgid bit on data partition mountpoint so directories and files
# inherit group permissions

[ "${DEVNAME}" != "/dev/mmcblk1p6" ] && exit 0

MNTNAME=/mnt/data
chgrp data "${MNTNAME}"
chmod 2774 "${MNTNAME}"  # setgid + rwx for group
