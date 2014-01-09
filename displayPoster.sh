#!/bin/bash
# File: displayPoster.sh
# Author: Philip M Hoffman II
# Description: If a movie has poster art

FILE=$1
POSTER_CACHE=/etc/mediatomb/.posters/cache
POSTER_FILE=$(basename "$FILE")
ART_REGEX='^ Metadata Cover Art pieces: [0-9]+'


#Use mp4info to determine if the file contains poster art
FILE_INFO=$(mp4info "$1" | grep "Metadata Cover Art pieces:")
if [[ $FILE_INFO =~ $ART_REGEX ]]; then
	#If the file contains poster art, Cache poster art to poster cache
	if [ ! -f "$POSTER_CACHE/${POSTER_FILE}.jpg" ]; then
		mp4art "$FILE" "$POSTER_CACHE/$POSTER_FILE"
	fi
	cp "$POSTER_CACHE/${POSTER_FILE}.jpg" "$2"
else
	#Otherwise, generate thumbnail & copy to PS3
	if [ ! -f "$POSTER_CACHE/FFMPEG_${POSTER_FILE}.jpg" ]; then
		ffmpegthumbnailer -i "$1" -o "$POSTER_CACHE/FFMPEG_${POSTER_FILE}.jpg" -s 160 -q 10
	fi
	cp "$POSTER_CACHE/FFMPEG_${POSTER_FILE}.jpg" "$2"
fi

