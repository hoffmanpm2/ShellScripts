#!/bin/bash
#Author: Philip M. Hoffman II
#Description: Searches media directory for videos without poster art.

VIDEO_DIR=$HOME/Media/Video
POSTER_DIR=$HOME/Media/Posters
find $VIDEO_DIR -not -iname *.m3u -not -iname *.ini -type f | while read FILE;
do
	POSTER_FILE=""
	if [[ $FILE == */TV\ Shows/* ]]; then
	        while IFS='/' read -ra MEDIA; do
                	if [[ ${MEDIA[8]} == Season* ]]; then
        	                POSTER_FILE="${MEDIA[7]} ${MEDIA[8]}.jpg"
	                else
                	        POSTER_FILE="${MEDIA[7]}.jpg"
        	        fi
	        done <<< $FILE

	elif [[ $FILE == */Workout/* ]]; then
                while IFS='/' read -ra MEDIA; do
                        FILE="${MEDIA[6]}"
                done <<< $$FILE

	else
		POSTER_FILE=${FILE##*/}.jpg
	fi

	if [ "$FILE" != "" ] &&  [ ! -f "$POSTER_DIR/$POSTER_FILE" ]; then
		echo "$FILE is missing poster art! - $POSTER_FILE"
	fi
done
