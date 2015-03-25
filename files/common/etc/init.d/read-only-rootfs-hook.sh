#!/bin/sh

. /etc/default/rcS

if [ "$ROOTFS_READ_ONLY" = "no" ]; then
    mount -n -o remount,rw /
    exit 0
fi

is_on_read_only_partition () {
	DIRECTORY=$1
	dir=`readlink -f $DIRECTORY`
	while true; do
		if [ ! -d "$dir" ]; then
			echo "ERROR: $dir is not a directory"
			exit 1
		else
			for flag in `awk -v dir=$dir '{ if ($2 == dir) { print "FOUND"; split($4,FLAGS,",") } }; \
				END { for (f in FLAGS) print FLAGS[f] }' < /proc/mounts`; do
				[ "$flag" = "FOUND" ] && partition="read-write"
				[ "$flag" = "ro" ] && { partition="read-only"; break; }
			done
			if [ "$dir" = "/" -o -n "$partition" ]; then
				break
			else
				dir=`dirname $dir`
			fi
		fi
	done
	[ "$partition" = "read-only" ] && echo "yes" || echo "no"
}

if [ "$1" = "start" ] ; then
	if [ `is_on_read_only_partition /var/lib` = "yes" ]; then
		grep -q "tmpfs /var/volatile" /proc/mounts || mount /var/volatile
		mkdir -p /var/volatile/lib
		# Do not copy rpm and opkg directories
		for f in $( ls /var/lib | sed "/\(rpm\|opkg\)/d" ); do
                        cp -a /var/lib/$f /var/volatile/lib
                done
		mount --bind /var/volatile/lib /var/lib
	fi
fi

