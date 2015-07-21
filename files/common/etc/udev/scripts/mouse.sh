#!/bin/bash

if [ "$ACTION" = "add" ]; then
	dbus-send --print-reply --system --dest=com.exor.EPAD '/' com.exor.EPAD.mouseNotification int32:1
else
	dbus-send --print-reply --system --dest=com.exor.EPAD '/' com.exor.EPAD.mouseNotification int32:0
fi


