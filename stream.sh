#!/bin/bash
#Twitch.tv or Justin.tv streaming script.
#Currently this streams your entire primary screen, I *should* be using some 
#code from my new puush script to grab the currently active window for streaming
#I have stripped my stream key from this script, insert your own
#I have not tested this in *many* months.
#Remove the "\" at the end of the second to last line and comment out the last line
#if you do not wish to have a local copy of your stream sessions
#Make sure to adjust the resolution on line 15 to match your display

KEY="YOUR_KEY_HERE"
TIMESTAMP=$(date "+%m-%d-%y @ %H%M") # My chosen timestamp for filename on my local copy
ffmpeg\
	-rtbufsize 204800000\
        -f x11grab -s 2560x1440 -r 60 -i :0.0+1920,0\
        -f alsa -ac 2 -i pulse\
        -vcodec libx264\
	-preset veryfast\
	-tune zerolatency\
	-x264opts keyint=350:partitions=none,i8x8,i4x4:me=umh:merange=16:subme=3:ref=1:mixed-refs=no:trellis=0:mbtree=no:weightp=0\
	-b:v 12280k -b:a 128k\
        -pix_fmt yuv420p\
        -acodec libmp3lame -ar 44100 -ab 128k\
        -threads 0\
        -f flv - |\
                ffmpeg -i - \
			-c copy -r 30 -f flv rtmp://live.justin.tv/app/$KEY \
			-c copy -f mp4 "/home/xaero/Videos/Recording on `echo $TIMESTAMP`.mp4"