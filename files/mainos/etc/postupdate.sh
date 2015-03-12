#!/bin/bash

# Started from rcS when
# /etc(ro) contains the new files from the update
# /etc(rw) is mounted on top of /etc and contains original files (before update)
# 
# 1. save files according to current version default file (the last default file in migrations folder before current version) copying files to a temp folder
# 2. iteratively applies migration steps:
#    a. update the default file list according to new default files in the migration folder and preserve newly preserved files or discard old preserved files no more in the default list
#    b. execute the migrate.sh script from the temporary preserved file path to change (migrate) preserved files, if existing
# 3. erase /etc(rw) and copy /etc(ro) over it
# 4. copy preserved files back to /etc(rw)
#

ROOTTMPMNT=$1
UPDATEPATH="/tmp"
PRESERVEDPATH="$UPDATEPATH/preservedFiles"

PACKAGEPATH="$ROOTTMPMNT/etc/migrations" 

# utilities
# Saves file in /tmp/preservedFiles
preserveFile() {
	echo "Preserving $1..."
	[ ! -e "$1" ] && return 0
	path="$( dirname $1 )"
	mkdir -p $PRESERVEDPATH/$path
	# Copy without override
	for f in $( find $1 ); do
		[ -d $f ] && mkdir -p $PRESERVEDPATH/$f && continue
		[ -f $PRESERVEDPATH/$f ] && continue
		cp -a $f $PRESERVEDPATH/$f
	done
}

# Removes file from /tmp/preservdFiles
discardFile() {
	echo "Removing $1 from preserved files..."
	[ -e "$PRESERVEDPATH/$1" ] && rm -rf $PRESERVEDPATH/$1
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
	[ -f "$PACKAGEPATH/to_$1/migrate.sh" ] && $PACKAGEPATH/to_$1/migrate.sh $PRESERVEDPATH
}

# Check if etc(ro) has a version file
[ ! -f "$PACKAGEPATH/version" ] && exit 0

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

# Check if we are going to do a downgrade. Migration and file preservation is not 
# supported for downgrades. Local files will be lost.
versionCompare $DEST_VERSION $CURR_VERSION
if [ $? = 255 ]; then
	rm -rf /etc/*
	# Copy updated etc file
	cp -a $ROOTTMPMNT/etc/. /etc
	exit 0
fi

mount -t tmpfs -o rw tmpfs $UPDATEPATH
mkdir -p $PRESERVEDPATH

# Get update steps list from directory names
VERSIONS=""
for d in $( ls "$PACKAGEPATH" | cat ); do
	[ ! -d "$PACKAGEPATH/$d" ] && continue
	ver="$( echo $d | sed s/to_// )"
	VERSIONS="$VERSIONS$ver "
done

# Look for the first default files to preserve in previous update steps
for v in $( echo "$VERSIONS" | tr " " "\n" | sort -r -n -t _ -k 1 -k 2 -k 3 ); do
	versionCompare $CURR_VERSION $v
	if [ ! $? = 255 -a -f $PACKAGEPATH/to_$v/default ]; then 
		currDefFile="$PACKAGEPATH/to_$v/default"
		break
	fi
done

# Preserve files for current version listed in default file
while read line; do
	line=$( echo "$line" | sed "s:\( *#.*$\|^ *\)::g" )
	[ -z "$line" ] && continue 
	file="/$(echo "$line" | sed "s:\(^/\|/* *$\)::g" )"
        [ -d "$file" ] && psvdDirs="$psvdDirs $file"
        file="$(echo "$file" | sed "s:/*\* *$::g" )"
	preserveFile "$file"
done < "$currDefFile"

# Iterative update from current to last installed version passing through all
# migration steps required
for v in $( echo "$VERSIONS" | tr " " "\n" | sort -n -t _ -k 1 -k 2 -k 3 ); do
	versionCompare $CURR_VERSION $v
	# If greater version
	if [ $? = 255 ]; then
		echo "Apply migration from " $CURR_VERSION " to " $v
		migrate $v
		CURR_VERSION=$v
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

umount $UPDATEPATH
