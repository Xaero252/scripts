#!/bin/bash
while true; do
	UPDATES=`yaourt -Qua | wc -l`

	if [[ "$UPDATES" -gt "10" ]]; then
		notify-send -i /usr/share/icons/Nitrux/apps/48/system-software-update.svg "$UPDATES Updates Available!"
	fi

	sleep 15m
done