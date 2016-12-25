#!/bin/bash
#"Borderless Fullscreen" automatic toggling script
#By Xaero252 @ OCN (overclock.net)
#Distributed with the "don't be a douche" license
#Just don't try and claim you thought this up or whatever

#Let's make sure we aren't already running
pidof -s -o '%PPID' -x $( basename $0 ) > /dev/null 2>&1 && exit

#First, let's start a container loop with a sleep command to keep it from eating CPU.
while true; do 
	sleep 1 #We'll use 1 second, we don't want users to wait forever.
	while read title; do
		xprop -name "$title" > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			win_found=1 #we found a window
			#check if it's fullscreen, set it to be if it's not
			if ! xprop -name "$title" 2> /dev/null | grep -q _NET_WM_STATE_FULLSCREEN; then
				echo "Found \"$title\" - setting fullscreen!"
				wmctrl -r "$title" -b toggle,fullscreen
			fi
		else
			win_found=0
		fi
	done < ~/.fullscreen.lst #This way it's per-user.
done
