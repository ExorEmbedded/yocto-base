#!/bin/bash

CMD_FILE="/mnt/data/updateCmd"
LOG_FILENAME="updateLog"
LOG_FILE="/mnt/data/$LOG_FILENAME"

quit() {
   if [ $1 -gt 0 ]; then
      msg="ERROR: $error"
   else
      msg="OPERATION COMPLETED"
   fi

   sleep 6

   echo -e "\n- Cleaning..."

   # Clean all, in any case
   [ -e "$pkg" ] && rm -rf "$pkg" "$pkg.md5"

   echo -e "\n\n--- EPAD OUTPUT ---"
   cat $LOG_FILE.epad
   echo -e "\n--- END EPAD OUTPUT ---"

   rm -rf $LOG_FILE.epad
   [ -e "/tmp/$LOG_FILENAME" ] && cp /var/run/$LOG_FILENAME /mnt/data
   sync

   # Get current OS
   versTag="$(cat /boot/version)";
   currOS="${versTag:8:1}"

   # Reboot to the OS we came from
   if [ "$currOS" == "C" ]; then
      dbus-send --print-reply --system --dest=com.exor.EPAD '/' com.exor.EPAD.restartSystemWithImage int32:0
   else
      dbus-send --print-reply --system --dest=com.exor.EPAD '/' com.exor.EPAD.restartSystemWithImage int32:1
   fi

   # Just in case EPAD fails
   echo -e "\nEPAD failed to reboot the system. Doing it manually..." >> /mnt/data/$LOG_FILENAME
   reboot -f
}

# Sync call to EPAD. Handles dbus signals
epad_sync() {

   echo	-e "\n- Executing EPAD call: dbus-send --print-reply --system --dest=com.exor.EPAD '/' com.exor.EPAD.$1 $2"

   dbus-send --print-reply --system --dest=com.exor.EPAD '/' com.exor.EPAD.$1 $2 &

   member=""

   echo -e "\n- Starting dbus signal listener..."

   while read line; do
      if ( echo "$line" | grep -q "member=progress" ); then
         member="progress"
         continue
      elif ( echo "$line" | grep -q "member=statusChanged" ); then
         member="statusChanged"
         continue
      fi

      case $member in
         "progress")
            # psplash progress now handled directly in EPAD
            member=""
            ;;
         "statusChanged")
            status=$( echo "$line" | awk '{print $2}' )
            case $status in
               2)
                  # Status ok
                  echo "Got status ok from EPAD!"
                  quit 0
                  ;;
               3)
                  # Status error
		  echo "Got error status from EPAD!"
                  member="error"
                  ;;
               *)
                  member=""
               esac
            ;;
         "error")
            error="$( echo "$line" | cut -d"\"" -f2 )"
            echo "ERROR: $error"
            quit 1
      esac

   done < <(dbus-monitor --system type='signal')
}


# Parse cmd file
cmd="$(cat "$CMD_FILE" | awk '{print $1}' )"
part="$(cat "$CMD_FILE" | awk '{print $2}' )"
pkg="$(cat "$CMD_FILE" | awk '{print $3}' )"

# In case we are on a Android panel
rm -rf '/mnt/data/$0030d8linux$.bin'

# Check cmd file owner. Should be root(0), admin(10000) or system(1000)
if ( stat -c %u "$CMD_FILE" | grep -vEq "0|1000|10000" ); then
   echo "Error: File owned by unauthorized user" > $LOG_FILE
   rm -rf "$CMD_FILE"
   exit
fi

rm -rf "$CMD_FILE"

if [ ! -f "$pkg" ]; then
   echo "Error: Update package not found" > $LOG_FILE
   exit
fi

mount -t tmpfs tmpfs /var/run

[ "$part" == "user" ] && LOG_FILE="/var/run/$LOG_FILENAME"

exec &>$LOG_FILE

echo "Found cmd file: $(cat $CMD_FILE)"

# Start EPAD manually so that we can have the log
echo -e	"\n- Starting EPAD..."
/usr/bin/EPAD &>$LOG_FILE.epad &

# Start dbus
echo -e	"\n- Starting dbus..."
mkdir -p /var/run/dbus
/etc/init.d/dbus-1 start

# Start udev
echo -e	"\n- Starting udev..."
/etc/init.d/udev start

# Wait for udev processing.
udevadm settle

case $cmd in
   "format")
      epad_sync formatImage "string:$part"
   ;;
   "update")
      epad_sync downloadImage "string:$part string:$pkg string: boolean:false"
   ;;
   *)
      echo -e "\nUnknown command: $cmd"
      rm -rf "$CMD_FILE"
      sync
      reboot -f
esac
