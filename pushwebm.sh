#!/bin/bash
#This script records the currently active window (to ram - keep this in mind) and uploads
#the resulting video to puush. Finally the url to the video on Puush is copied to your clipboard
#one or two bugs still, I'm sure - but it works mostly for me, I need to rewrite this at some point
#Suggested to keybind the script so you can quickly capture video clips. Press the key once to start
#and then once again to stop recording. 

##DEBUGGING SHIT
exec > >(tee ~/pushwebm.log)
exec 2>&1

##USER TUNABLES##
##Generic Settings
#Enable or disable notifications (both enabled by default)
audible_notification=true
visual_notification=true
#Timestamp to mark recordings with - to keep things organized
timestamp=$(date "+%m-%d-%y @ %H%M")
#sizes can be anything find acepts. Maximum size puush accepts is 20M (default)
upload_cutoff="+20M"
#Below icons are able to be defined as absolute paths or icon names from the currently selected icon set (/usr/share/icons)
record_icon=gtk-media-record
stop_icon=gtk-media-stop
puush_icon=media-playlist-shuffle
#This sound should be an mp3 format sound blip
puush_sound="$HOME/.sounds/puush.mp3"
#Move all videos (true), or just those that don't get uploaded (false)
archive_all_videos=true

##Recording Settings (mostly self explanitory)
framerate=60
video_storage_dir="$HOME/Videos"
video_container="mp4"
video_codec="libx264"
video_codec_preset="ultrafast"
audio_codec="libmp3lame"
audio_channels="2"

#Alsa users: whatever recording device you wish, microphone or otherwise, you can also use snd-aloop to create a monitor
#Pulse users: you should be able to set this to pulse and then use pavucontrol (or whatever) to select a recording device
#You should be able to figure this out with arecord -l, hw:<card>,<device> for ALSA.
audio_device="pulse"
audio_samplerate="44100"
audio_bitrate="128k"

#Limit video resolution to no more than current monitor size? (useful for strange fullscreen window behaviors) Default: true
limit_res=true


#Don't Touch these variables
keyframes=$((framerate*2))
friendlytitle=$(xprop -id `xprop -root | grep "_NET_ACTIVE_WINDOW(WINDOW)" | awk '{print $5}'` | grep "WM_CLASS(STRING)" | sed -e 's/.*= "\([^"]*\)".*/\1/')
filename="${friendlytitle} on ${timestamp}.$video_container"
maxresx=$(xdotool getdisplaygeometry | awk '{print $1}')
maxresy=$(xdotool getdisplaygeometry | awk '{print $2}')

if [ ! -f /tmp/.record ];then
	touch /tmp/.record

	#Below Snippet taken from:
	#http://ur1.ca/iu5rm
	# Get the coordinates of the active window's
	#    top-left corner, and the window's size.
	#    This excludes the window decoration.
	  unset x y w h
	  eval $(xwininfo -id $(xdotool getactivewindow) |
	    sed -n -e "s/^ \+Absolute upper-left X: \+\([0-9]\+\).*/x=\1/p" \
	           -e "s/^ \+Absolute upper-left Y: \+\([0-9]\+\).*/y=\1/p" \
	           -e "s/^ \+Width: \+\([0-9]\+\).*/w=\1/p" \
	           -e "s/^ \+Height: \+\([0-9]\+\).*/h=\1/p" )
	#End Snippet

	if $limitres; then

		if [ "$w" -gt "$maxresx" ];then
			w="$maxresx"
		fi

		if [ "$h" -gt "$maxresy" ];then
			h="$maxresy"
		fi
	fi

	#Now that we know where the current window is, and how big it is
	#we can use this to record the window - but only if it doesn't move
	##FIXME - DOES NOT FOLLOW ACTIVE WINDOW##

	size="${w}x${h}"
	
	tmp_name="/tmp/${filename}"

	ffmpeg_command=$(echo "ffmpeg -y -video_size $size -framerate $framerate -f x11grab -i $DISPLAY+$x,$y -f alsa -ac $audio_channels -i $audio_device -vcodec $video_codec -preset $video_codec_preset -acodec $audio_codec -ar $audio_samplerate -ab $audio_bitrate -g $keyframes \"$tmp_name\"&")
	eval "$ffmpeg_command"

	FFMPEG_PID=$!

	if $visual_notification;then
		notify-send -i $record_icon "Started Recording"&
	fi

	while [ -f /tmp/.record ];do
		sleep 0.05
	done

	kill -SIGTERM $FFMPEG_PID && wait  #kill ffmpeg, the .record file has been removed. wait for things to clean up
	puushed=false

	if [[ $(find $tmp_name -type f -size $upload_cutoff 2>/dev/null) ]] || $archive_all_videos; then
		cp_command=$(echo "cp '$tmp_name' '$video_storage_dir'&")
		eval $cp_command&
	fi

	if [[ ! $(find $tmp_name -type f -size $upload_cutoff 2>/dev/null) ]]; then
		
		(puush "$tmp_name" | grep http | tr -d '\n' | xclip -selection c.)&
		puushed=true
	fi

	if $visual_notification;then

		if $puushed; then
			notif_string='"Stopped Recording" "Uploading to Puush"'
		else
			notif_string='"Stopped Recording" "Archiving Video"'
		fi
		
		notif_command=$(echo "notify-send -i $stop_icon $notif_string")
		eval $notif_command&
	fi
	
	wait

	if $puushed;then
		if $visual_notification;then
			notify-send -i $puush_icon "Puush Complete!"&
		fi
		
		if $audible_notification;then
			mpg123 $puush_sound
		fi
	fi
	rm "$tmp_name"
else
		rm /tmp/.record
fi
