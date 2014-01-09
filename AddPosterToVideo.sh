#!/bin/bash

VIDEO_FILE=$1
POSTER_PATH=$HOME/Media/Posters
POSTER_FILE=${VIDEO_FILE##*/}.jpg

#If poster is found, embed it in mp4 file
if [ -f "$POSTER_PATH/$POSTER_FILE" ]; then
	mp4tags -P "$POSTER_PATH/$POSTER_FILE" "$VIDEO_FILE"
fi
