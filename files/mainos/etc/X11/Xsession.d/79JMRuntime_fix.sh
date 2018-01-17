#! /bin/sh

if  grep JMobile /mnt/data/hmi/qthmi/run.sh > /dev/null 2>&1 ; then
   sed -i"" "/JMLauncher.app/s/JMobile/HMI Runtime/" /mnt/data/hmi/qthmi/run.sh
   sync
fi
