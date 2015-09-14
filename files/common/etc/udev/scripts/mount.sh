#!/bin/sh
#
# Called from udev
#
# Attempt to mount any added block devices and umount any removed devices

MOUNT="/bin/mount"
PMOUNT="/usr/bin/pmount"
UMOUNT="/bin/umount"
FSCK="/sbin/fsck"

# Device-specific options
if echo $myname | grep -q usbmemory; then
	MOUNT_ARGS="-o gid=admin,umask=002"  # writable by admin group
fi

# Otherwise fsck won't find some executables
PATH="/usr/gnu/bin:/usr/local/bin:/bin:/usr/bin:.:/usr/sbin"
export PATH

for line in `grep -v ^# /etc/udev/mount.blacklist`
do
	if [ ` expr match "$DEVNAME" "$line" ` -gt 0 ];
	then
		logger "udev/mount.sh" "[$DEVNAME] is blacklisted, ignoring"
		exit 0
	fi
done

automount() {
	if [ -z "$myname" ]; then
		if [ -z "$ID_FS_LABEL" ]; then
			name="`basename "$DEVNAME"`"
		else
			name="`basename "$ID_FS_LABEL"`"
		fi
	else
		name="$myname"
	fi

	name=${name,,}

	! test -d "/mnt/$name" && mkdir -p "/mnt/$name"
	# Silent util-linux's version of mounting auto
	if [ "x`readlink $MOUNT`" = "x/bin/mount.util-linux" ] ;
	then
		MOUNT_ARGS="$MOUNT_ARGS -o silent"
	fi

	[ -n "$opts" ] && MOUNT_ARGS="$MOUNT_ARGS -o $opts"

	if ! $MOUNT -t auto $MOUNT_ARGS $DEVNAME "/mnt/$name"
	then
		#logger "mount.sh/automount" "$MOUNT -t auto $MOUNT_ARGS $DEVNAME \"/mnt/$name\" failed!"
		rm_dir "/mnt/$name"
	else
		logger "mount.sh/automount" "Auto-mount of [/mnt/$name] successful"
		touch "/tmp/.automount-$name"
	fi
}

rm_dir() {
	# We do not want to rm -r populated directories
	if test "`find "$1" | wc -l | tr -d " "`" -lt 2 -a -d "$1"
	then
		! test -z "$1" && rm -r "$1"
	else
		logger "mount.sh/automount" "Not removing non-empty directory [$1]"
	fi
}

(
# do in parallel since can take some time

if [ "$ACTION" = "add" ] && [ -n "$DEVNAME" ] && [ -n "$ID_FS_TYPE" ]; then
	# Do not perform fsck if device is already mounted
	[ -z "$( grep "$DEVNAME" /etc/mtab)" ] && [ "$ID_FS_TYPE" != "vfat"  ] && $FSCK -a $DEVNAME
	if [ -x "$PMOUNT" ]; then
		$PMOUNT $MOUNT_ARGS $DEVNAME 2> /dev/null
	elif [ -x $MOUNT ]; then
		$MOUNT $MOUNT_ARGS $DEVNAME 2> /dev/null
	fi
	
	# If the device isn't mounted at this point, it isn't
	# configured in fstab (note the root filesystem can show up as
	# /dev/root in /proc/mounts, so check the device number too)
	if expr $MAJOR "*" 256 + $MINOR != `stat -c %d /`; then
		grep -q "^$DEVNAME " /proc/mounts || automount
	fi
fi

if [ "$ACTION" = "remove" ] && [ -x "$UMOUNT" ] && [ -n "$DEVNAME" ]; then
	for mnt in `cat /proc/mounts | grep "$DEVNAME" | cut -f 2 -d " " `
	do
		$UMOUNT -l $mnt # lazy umount in case files are in use
	done
	
	# Remove empty directories from auto-mounter
	if [ -z "$myname" ]; then
		if [ -z "$ID_FS_LABEL" ]; then
			name="`basename "$DEVNAME"`"
		else
			name="`basename "$ID_FS_LABEL"`"
		fi
	else
		name="$myname"
	fi  

	name=${name,,}

	test -e "/tmp/.automount-$name" && rm_dir "/mnt/$name"
fi

)&
