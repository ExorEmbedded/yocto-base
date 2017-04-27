#!/bin/bash

# Started from rcS when
# /etc(ro) contains the new files from the update
# /etc(rw) is mounted on top of /etc and contains original files (before update)
#
# 1. save files according to current version default file (the last default file in migrations folder before current version) copying files to a temp folder
# 2. iteratively applies migration steps:
#    a. update the default file list according to new default files in the migration folder and preserve newly preserved files or discard old preserved files no more in the default list
#    b. execute the pre.sh and post.sh scripts from the temporary preserved file path to change (migrate) preserved files, if existing
# 3. erase /etc(rw) and copy /etc(ro) over it
# 4. copy preserved files back to /etc(rw)
#

UPDATEPATH="/tmp"
PRESERVEDPATH="$UPDATEPATH/preservedFiles"

PACKAGEPATH="$ROOTTMPMNT/etc/migrations"

mount -t tmpfs -o rw tmpfs /var/volatile
mkdir -p /var/volatile/tmp
mkdir -p $PRESERVEDPATH

rotation=0
[ -e /etc/rotation ] && read rotation < /etc/rotation

# Restart psplash with --notouch
psplash-write "QUIT"
sleep 2
/usr/bin/psplash --notouch --angle $rotation &

currProgress=0
numSteps=0

#
# utilities
#

# Updates progress bar by specifies amount
update_progress() {
	currProgress=$(( $currProgress + $1 ))
	psplash-write "PROGRESS $currProgress"
}

# Create a directory preserving permissions
#
# $1: dir to create
# $2: dir to copy permissions from
mkdirPreserve() {
    [ -e $1 ] && return 0

    mkdir -p $1
    chown $(stat -c "%U" $2) $1
    chgrp $(stat -c "%G" $2) $1
    chmod $(stat -c "%a" $2) $1
}

# TODO
#   - this handles permissions only of directories specified in 'default' file and their children;
#     if we ever need to preserve permissions of ancestors (e.g. one/two/three), this will need to be extended
#
# Saves file in /tmp/preservedFiles
preserveFile() {
        echo "Preserving $1..."
        [ ! -e "$1" ] && return 0
        path="$( dirname $1 )"
        mkdirPreserve $PRESERVEDPATH/$path $path
        # Copy without override
        for f in $( find $1 ); do
                [ -d $f ] && mkdirPreserve $PRESERVEDPATH/$f $f && continue
                [ -f $PRESERVEDPATH/$f ] && continue
                cp -a $f $PRESERVEDPATH/$f
        done
}

# Removes file from /tmp/preservedFiles
discardFile() {
        echo "Removing $1 from preserved files..."
        [ -e "$PRESERVEDPATH/$1" ] && rm -rf $PRESERVEDPATH/$1
}

# Post-processing to merge init scripts (rc5.d only)
#
# Requires special handling so priorities can be changed but on/off settings remain
preserveInit() {
        local preservedName
        local newName
        local found

        echo "Migrating init script settings"

        for newFile in $(ls ${ROOTTMPMNT}/etc/rc5.d); do
                newName=${newFile:3}
                found=0
                for preservedFile in $(ls ${PRESERVEDPATH}/etc/rc5.d); do
                        preservedName=${preservedFile:3}
                        if [ "${newName}" = "${preservedName}" ]; then
                                if [ "${preservedFile}" != "${newFile}" ]; then
                                        echo "[CASE 1] Migrating changed init order: '${preservedFile}' -> '${newFile}'"
                                        mv ${PRESERVEDPATH}/etc/rc5.d/${preservedFile} ${PRESERVEDPATH}/etc/rc5.d/${newFile}
                                fi
                                found=1
                                break
                        fi
                done
                if [ $found -eq 0 ]; then
                        if [ -r ${PRESERVEDPATH}/etc/rc5.d/.${newName}.disabled ]; then
                            echo "[CASE 2a] Script '${newName}' was disabled by user: doing nothing"
                        else
                            echo "[CASE 2b] Script '${newFile}' not found in settings: copying from root"
                            cp -a ${ROOTTMPMNT}/etc/rc5.d/${newFile} ${PRESERVEDPATH}/etc/rc5.d/
                        fi
                fi
        done

        for preservedFile in $(ls ${PRESERVEDPATH}/etc/rc5.d); do
                preservedName=${preservedFile:3}
                found=0
                for newFile in $(ls ${ROOTTMPMNT}/etc/rc5.d); do
                        newName=${newFile:3}
                        if [ "${newName}" = "${preservedName}" ]; then
                                found=1
                                break;
                        fi
                done
                if [ $found -eq 0 ]; then
                    if [ -e ${ROOTTMPMNT}/etc/init.d/${preservedName} ]; then
                        echo "[CASE 3a] Script '${preservedName}' enabled in settings but not in rootfs: keeping preference"
                    else
                        echo "[CASE 3b] Script '${preservedName}' found in settings but not in rootfs: removing file"
                        rm ${PRESERVEDPATH}/etc/rc5.d/${preservedFile}
                    fi
                fi
        done
}

# Input: [version1] [version2] , eg 1_2_3 5_6_7
# Returns: 255 if version1  version2
#            0 if version1 == version2
#            1 if version1 >  version2
versionCompare() {
        M1=$( echo $1 | cut -d_ -f1 )
        m1=$( echo $1 | cut -d_ -f2 )
        b1=$( echo $1 | cut -d_ -f3 )
        M2=$( echo $2 | cut -d_ -f1 )
        m2=$( echo $2 | cut -d_ -f2 )
        b2=$( echo $2 | cut -d_ -f3 )

	# Sanity check: unstable update steps should not be here
	[ $m2 -eq 999 ] && return 0

        if [ $M1 -lt $M2 ]; then
                return 255
        elif [ $M1 -gt $M2  ]; then
                return 1
        fi
        if [ $m1 -lt $m2 ]; then
                return 255
        elif [ $m1 -gt $m2  ]; then
                return 1
        fi
        if [ $b1 -lt $b2 ]; then
                return 255
        elif [ $b1 -gt $b2  ]; then
                return 1
        fi
        return 0
}

# Do changes required from an update step
migrate() {
	[ -f "$PACKAGEPATH/to_$1/pre.sh" ] && $PACKAGEPATH/to_$1/pre.sh $PRESERVEDPATH
	# Update preserved files
        if [ -f "$PACKAGEPATH/to_$1/default" ]; then
                # Find files to discard by comparing old default file with new one
                if [ -f "$currDefFile" ]; then
                        while read line; do
                                line=$( echo "$line" | sed "s:\( *#.*$\|^ *\)::g" )
                                [ -z "$line" ] && continue
                                file="$(echo "$line" | sed "s:\(^/\|\**/* *$\)::g" )"
                                [ -z "$( grep "^/*$file/*\** *$" $PACKAGEPATH/to_$1/default )" ] && discardFile "/$file"
                        done < "$currDefFile"
                fi
                # Copy files to preserve
                psvdDirs=""
                while read line; do
                        line=$( echo "$line" | sed "s:\( *#.*$\|^ *\)::g" )
                        [ -z "$line" ] && continue
                        file="/$(echo "$line" | sed "s:\(^/\|/* *$\)::g" )"
                        [ -d "$file" ] && psvdDirs="$psvdDirs $file"
                        file="$(echo "$file" | sed "s:/*\* *$::g" )"
                        preserveFile "$file"
                done < $PACKAGEPATH/to_$1/default
                currDefFile="$PACKAGEPATH/to_$1/default"
        fi
        # Execute migration script
        [ -f "$PACKAGEPATH/to_$1/post.sh" ] && $PACKAGEPATH/to_$1/post.sh $PRESERVEDPATH
}

# Check if etc(ro) has a version file
[ ! -f "$PACKAGEPATH/version" ] && return

# Get current /etc(rw) version
rwEtcV="$( cat /etc/migrations/version )"
maj=$( echo ${rwEtcV:9:2} | sed "s:^0::" )
min=$( echo ${rwEtcV:11:3} | sed "s:\(^0\|^00\)::" )
b=$( echo ${rwEtcV:14:3} | sed "s:\(^0\|^00\)::" )
CURR_VERSION="${maj}_${min}_${b}"

# Get current bsp version
bspV="$( cat /boot/version )"
maj=$( echo ${bspV:9:2} | sed "s:^0::" )
min=$( echo ${bspV:11:3} | sed "s:\(^0\|^00\)::" )
b=$( echo ${bspV:14:3} | sed "s:\(^0\|^00\)::" )
DEST_VERSION="${maj}_${min}_${b}"

psplash-write "MSG Please wait while updating os ... "

# Check if we are going to do a downgrade. Migration and file preservation is not
# supported for downgrades. Local files will be lost.
versionCompare $DEST_VERSION $CURR_VERSION
if [ $? = 255 ]; then
        rm -rf /etc/*
        # Copy updated etc file
        cp -a $ROOTTMPMNT/etc/. /etc
        [ ! -e $FACTORYTMPMNT'shadow' ] && cp /etc/shadow $FACTORYTMPMNT
        ln -s -b $FACTORYTMPMNT'shadow' /etc/shadow
        sync
        umount /var/volatile
        psplash-write "PROGRESS 100"

        # Restart psplash
        psplash-write "QUIT"
        sleep 2
        /usr/bin/psplash --angle $rotation &
        return
fi

# Get update steps list from directory names
VERSIONS=""
for d in $( ls "$PACKAGEPATH" | cat ); do
        [ ! -d "$PACKAGEPATH/$d" ] && continue
        ((numSteps++))
	ver="$( echo $d | sed s/to_// )"
        VERSIONS="$VERSIONS$ver "
done

# Look for the first default files to preserve in previous update steps
for v in $( echo "$VERSIONS" | tr " " "\n" | sort -r -n -t _ -k 1 -k 2 -k 3 ); do
        versionCompare $CURR_VERSION $v
        if [ ! $? = 255 ]; then
		((numSteps--)) 
		[ -f $PACKAGEPATH/to_$v/default -a -z "$currDefFile" ] && currDefFile="$PACKAGEPATH/to_$v/default"
        fi
done

numSteps=$(( $numSteps + 2))
step=$(( 100 / $numSteps ))

# Preserve files for current version listed in default file
while read line; do
        line=$( echo "$line" | sed "s:\( *#.*$\|^ *\)::g" )
        [ -z "$line" ] && continue
        file="/$(echo "$line" | sed "s:\(^/\|/* *$\)::g" )"
        [ -d "$file" ] && psvdDirs="$psvdDirs $file"
        file="$(echo "$file" | sed "s:/*\* *$::g" )"
        preserveFile "$file"
done < "$currDefFile"

preserveInit

update_progress $step

# Iterative update from current to last installed version passing through all
# migration steps required
for v in $( echo "$VERSIONS" | tr " " "\n" | sort -n -t _ -k 1 -k 2 -k 3 ); do
        versionCompare $CURR_VERSION $v
        # If greater version
        if [ $? = 255 ]; then
                echo "Apply migration from " $CURR_VERSION " to " $v
                migrate $v
                CURR_VERSION=$v
		update_progress $step
        fi
done

rm -rf /etc/*

# Copy updated etc file
cp -a $ROOTTMPMNT/etc/. /etc

# Remove preserved directories
for dir in $psvdDirs; do
        rm -rf $dir
done

# Finally restore preserved and migrated files
cp -a $PRESERVEDPATH/etc/. /etc

[ ! -e $FACTORYTMPMNT'shadow' ] && cp /etc/shadow $FACTORYTMPMNT
ln -s -b $FACTORYTMPMNT'shadow' /etc/shadow

psplash-write "PROGRESS 100"

umount /var/volatile

# Restart psplash 
psplash-write "QUIT"
sleep 2
/usr/bin/psplash --angle $rotation &

# This script is sourced by /etc/init.d/rcS - don't exit
#exit 0
