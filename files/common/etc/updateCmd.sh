#!/bin/bash

CMD_FILE="/mnt/data/updateCmd"
LOG_FILENAME="updateLog"

quit() {
   if [ $1 -gt 0 ]; then
      msg="ERROR: $error"
   else
      msg="OPERATION COMPLETED"
   fi

   psplash-write "MSG $msg"
   psplash-write "PROGRESS 100"
   sleep 6

   echo -e "\n- Cleaning..."

   # Clean all, in any case
   [ -e "$pkg" ] && rm -rf "$pkg" "$pkg.md5"
   # In case we are on a Android panel
   rm -rf '/mnt/data/$0030d8linux$.bin'

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

# Sync call to EPAD. Handles dbus signals and psplash loading bar
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
            progress=$( echo "$line" | awk '{print $2}' )
            if [ $progress -gt $(( $current + $step_length )) ]; then
               current=$(( $current + $step_length))
               psplash-write "PROGRESS $current"
            fi
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

mount -t tmpfs tmpfs /var/run

if [ "$part" == "user" ]; then
   LOG_FILE="/var/run/$LOG_FILENAME"
else
   LOG_FILE="/mnt/data/$LOG_FILENAME"
fi

exec &>$LOG_FILE

# Check cmd file owner. Should be root(0), admin(10000) or system(1000)
if ( stat -c %u "$CMD_FILE" | grep -vEq "0|1000|10000" ); then
   echo "Error: File owned by unauthorized user"
   rm -rf "$CMD_FILE"
   exit
fi

echo "Found cmd file: $(cat $CMD_FILE)"

rm -rf "$CMD_FILE"

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

echo -e "\n- Restarting psplash with --notouch..."
psplash-write "QUIT"
sleep 2
/usr/bin/psplash --notouch &

# Wait for udev processing.
udevadm settle

# Psplash loading bar handling
STEPS=6
current=0
step_length=$((100/$STEPS))

case $cmd in
   "format")
      psplash-write "MSG Clearing $part..."
      epad_sync formatImage "string:$part"
   ;;
   "update")
      psplash-write "MSG Upadating $part..."
      epad_sync downloadImage "string:$part string:$pkg string: boolean:false"
   ;;
   *)
      echo -e "\nUnknown command: $cmd"
      rm -rf "$CMD_FILE"
      sync
      reboot -f
esac
