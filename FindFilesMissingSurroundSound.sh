#!/bin/bash
# AddStereoAudioTrack.sh
# Description: Adds a stereo aac audio track to high-definition videos so they can be transcoded into Flash video format (*.flv)
# Author: Philip M. Hoffman II
#
# Breakdown:
#  - Find first high-definition video file
#  - Check for an aac stereo audio track
#    + If audio track is missing
#      - Create a copy of the high-definition video file
#      - Copy 5.1 audio track in copied high-definition file to temporary file
#      - Downmix temporary audio file to stereo & output to stdout
#      - Encode stereo audio track into aac
#      - Add stereo aac track to the copied high-definition video file
#      - Verify the copied high-definition video file has a stereo audio track
#      - Overwrite the original high-definition video file with its copy
#      - Clean-up any temporary files created during the process

FILE="$1"
TEMP_PATH="$HOME/.tmp"
if [ "$FILE" != "" ]; then
        if [ -f "$FILE" ]; then
                #Regular expressions for ffmpeg streams
                VIDEO_REGEX='^    Stream #[0-9]+\.[0-9]+\(.+\): Video: (.+), (.+), ([0-9]+x[0-9]+) \[PAR [0-9]+:[0-9]+ DAR [0-9]+:[0-9]+\], (.+)$'
                AUDIO_REGEX='^    Stream #[0-9]+\.[0-9]+\([^\)]+\): Audio: ([^,]+), ([0-9]+) Hz, (.+)$'

                #Retrieve video information using ffmpeg
                FILE_INFO=$(ffmpeg -i "$FILE" 2>&1)
                VIDEO_INFO=$(echo "$FILE_INFO" | grep '^    Stream' | grep 'Video')
                STEREO_INFO=$(echo "$FILE_INFO" | grep '^    Stream' | grep '5.1')

                #Grab video info & determine if we have high-definition content
                if [[ $VIDEO_INFO =~ $VIDEO_REGEX ]]; then
                        RESOLUTION=( $(echo ${BASH_REMATCH[3]} | tr 'x', ' ') )
                        if [ ${RESOLUTION[0]} -gt 720 ]; then
                                if [ ${RESOLUTION[1]} -gt 480 ]; then
					if [ "$STEREO_INFO" = "" ]; then
						echo $FILE
					fi
				fi
			fi
		fi
	fi
fi

