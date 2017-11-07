#!/bin/bash
#
# Preupdate script file
#
# NOTE: currently called only when updating MainOS (from ConfigOS)

MAINOS_ROOT="/mnt/mainos"
SETTINGS_ROOT="/mnt/etc"

# Handle special case for init script migration: postupdate.sh cannot distinguish between services which 
# have been disabled by user (must stay disabled), and new services which are not in settings yet
# (to be installed), so we mark services which are disabled in settings. 
# Case where user has enabled services which are disabled in image is already handled in postupdate.sh.
markInitDisabled()
{
    local name

    mount -o remount,rw ${SETTINGS_ROOT}

    rm -f ${SETTINGS_ROOT}/rc5.d/.*.disabled

    for script in $(ls ${MAINOS_ROOT}/etc/rc5.d/); do
        name=${script:3}

        if ! ls ${SETTINGS_ROOT}/rc5.d/ | grep -q "S[0-9][0-9]${name}$"; then
            echo "Marking '${name}' as disabled"
            touch ${SETTINGS_ROOT}/rc5.d/.${name}.disabled
        fi
    done

    mount -o remount,ro ${SETTINGS_ROOT}
}

markInitDisabled

exit 0
