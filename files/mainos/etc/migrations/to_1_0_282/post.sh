#!/bin/bash

PRESERVEDPATH=$1
[ -z $PRESERVEDPATH ] && exit 1

# We do not use services-vnc.json anymore. If VNC was enabled we need
# to set a specific system parameter to keep this option
if [ -e /etc/jmuconfig/services-vnc.json ]; then

   if ( cat /etc/jmuconfig/services-vnc.json | grep -q '"enabled": true' ); then
      /usr/bin/sys_params -w services/x11vnc/autostart true
      cp /etc/EPAD/system.ini $PRESERVEDPATH/etc/EPAD/
   fi

   rm -rf /etc/jmuconfig/services-vnc.json
   rm -rf $PRESERVEDPATH/etc/jmuconfig/services-vnc.json
   sync
fi
