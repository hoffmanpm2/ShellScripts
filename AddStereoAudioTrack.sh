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
TEMP_PATH="$HOME/Temp"
if [ ! -d "$TEMP_PATH" ]; then
	mkdir "$TEMP_PATH"
fi

if [ "$FILE" != "" ]; then
	if [ -f "$FILE" ]; then
		#Regular expressions for ffmpeg streams
		VIDEO_REGEX='^    Stream #[0-9]+\.[0-9]+\(.+\): Video: (.+), (.+), ([0-9]+x[0-9]+) \[PAR [0-9]+:[0-9]+ DAR [0-9]+:[0-9]+\], (.+)$'
		AUDIO_REGEX='^    Stream #[0-9]+\.[0-9]+\([^\)]+\): Audio: ([^,]+), ([0-9]+) Hz, (.+)$'

		#Retrieve video information using ffmpeg
		FILE_INFO=$(ffmpeg -i "$FILE" 2>&1)
		VIDEO_INFO=$(echo "$FILE_INFO" | grep '^    Stream' | grep 'Video')
		STEREO_INFO=$(echo "$FILE_INFO" | grep '^    Stream' | grep 'stereo')

		#Grab video info & determine if we have high-definition content
		if [[ $VIDEO_INFO =~ $VIDEO_REGEX ]]; then
			RESOLUTION=( $(echo ${BASH_REMATCH[3]} | tr 'x', ' ') )
			if [ ${RESOLUTION[0]} -gt 720 ]; then
				if [ ${RESOLUTION[1]} -gt 480 ]; then
					#Grab audio info & determine if we have a stereo track
					if [ "$STEREO_INFO" = "" ]; then
						FILE_COPY="$TEMP_PATH/$(basename "$FILE")"
						echo "File: $FILE"
						echo "-------------------------"
						echo " - Copying $(basename "$FILE") to $FILE_COPY"
						if [ -d "$TEMP_PATH" ]; then
							cp "$FILE" "$FILE_COPY"
						else
							mkdir "$TEMP_PATH"
							cp "$FILE" "$FILE_COPY"
						fi

						#Extract 5.1 audio track from video
						echo " - Extracting 5.1 aac track from $FILE_COPY"
						ffmpeg -v 0 -i "$FILE_COPY" -vn -acodec copy "$FILE_COPY.m4a" > /dev/null 2>&1

						#Downmix 5.1 audio to stereo aac track
						echo " - Downmixing $FILE_COPY.m4a to stereo & adding the track to $FILE_COPY.mp4"
						faad --downmix --quiet --stdio "$FILE_COPY.m4a" | ffmpeg -v 0 -i "$FILE_COPY" -i - -vcodec copy -map 0.0 -acodec copy -map 0.1 -acodec libfaac -async 48000 -map 1.0 "$FILE_COPY.mp4" -newaudio > /dev/null 2>&1

						REENCODED_FILE_INFO=$(ffmpeg -i "$FILE_COPY.mp4" 2>&1)
						REENCODED_STEREO_INFO=$(echo "$REENCODED_FILE_INFO" | grep '^    Stream' | grep 'stereo')

						if [ "$REENCODED_STEREO_INFO" != "" ]; then
							echo " - Verified $FILE_COPY contains stereo track"
							echo ""

							#Overwrite video file
							mv "$FILE_COPY.mp4" "$FILE_COPY"
							mv "$FILE_COPY" "$FILE"
							rm "$FILE_COPY.m4a"

							#Fix file permissions
							USER=$(whoami)
							chown $USER.users "$FILE"
							chmod 755 "$FILE"
						fi
					fi
				fi
			fi
		fi
	fi
fi
		
