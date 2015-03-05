#!/bin/bash
#
# Activate setgid bit on data partition mountpoint so directories and files
# inherit group permissions

MNTNAME=$(grep ${DEVNAME} /proc/mounts | awk '{print $2}')
chgrp data "${MNTNAME}"
chmod 2774 "${MNTNAME}"  # setgid + rwx for group
