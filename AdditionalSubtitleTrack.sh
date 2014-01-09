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
                #Retrieve video information using ffmpeg
                FILE_INFO=$(echo $(ffmpeg -i "$FILE" 2>&1) | grep 'Subtitle:')

                #Grab video info & determine if we have high-definition content
		if [ "$FILE_INFO" != "" ]; then
			echo $FILE
		fi
	fi
fi

