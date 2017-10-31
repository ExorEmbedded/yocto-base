#!/bin/bash

PRESERVEDPATH=$1
[ -z $PRESERVEDPATH ] && exit 1

# Clear Cloud Service Settings from both root and preserved path [#872]
rm -rf $PRESERVEDPATH/etc/jmuconfig/services-cloud*
rm -rf /etc/jmuconfig/services-cloud*
rm -rf $PRESERVEDPATH/etc/rc*.d/*encloud
rm -rf /etc/rc*.d/*encloud
sync
