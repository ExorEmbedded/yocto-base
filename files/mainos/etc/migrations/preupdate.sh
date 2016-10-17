#!/bin/bash
#
# Preupdate script file

# Handle special case for init script migration: postupdate.sh cannot distinguish between services which 
# have been disabled by user (must stay disabled), and new services which are not in settings yet
# (to be installed), so we mark services which are disabled in settings. 
# Case where user has enabled services which are disabled in image is already handled in postupdate.sh.
markInitDisabled()
{
    local name
    local rootTmp

    rootTmp=/mnt/tmpRoot
    mkdir -p ${rootTmp}
    mount -o bind / ${rootTmp}

    rm -f /etc/rc5.d/.*.disabled

    for script in $(ls ${rootTmp}/etc/rc5.d/); do
        name=${script:3}

        if ! ls /etc/rc5.d/ | grep -q "S[0-9][0-9]${name}$"; then
            echo "Marking '${name}' as disabled"
            touch /etc/rc5.d/.${name}.disabled
        fi
    done

    umount -l ${rootTmp}
    rm -rf ${rootTmp}
}

markInitDisabled

exit 0
