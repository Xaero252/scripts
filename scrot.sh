#!/bin/bash
#Dependencies; puush (available on the AUR, and github), xprop, scrot, xclip
#Optional dependencies: mpg123 (for audible alert), notify-send (libnotify, visual alert)
#Takes a screenshot of the currently focused window, uploads the screenshot to puush and places the link in your clipboard
#Suggested use: bind this script to a key to use for puushing screenshots
#User Tunables
timestamp=$(date "+%m-%d-%y @ %H%M") #timestamp to use in the filename
puush_sound="$HOME/.sounds/puush.mp3" #you can point this to any sound you wish to use
puush_icon=media-playlist-shuffle #icon name, get this from /usr/share/icons/<theme>/32x32/
#No more variables to adjust
friendlytitle=$(xprop -id `xprop -root | grep "_NET_ACTIVE_WINDOW(WINDOW)" | awk '{print $5}'` | grep "WM_CLASS(STRING)" | sed -e 's/.*= "\([^"]*\)".*/\1/')

filename="/tmp/${friendlytitle} on ${timestamp}.png"
scrot -u "$filename"
echo $filename
puush "$filename" | grep http | tr -d '\n' | xclip -selection c.
wait
notify-send -i $puush_icon "Puush Complete!"&
mpg123 $puush_sound
rm "$filename"
