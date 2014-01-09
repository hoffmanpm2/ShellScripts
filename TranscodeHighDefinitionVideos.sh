#!/bin/bash
# File: TranscodeHighDefinitionVideos.sh
# Description: Searches input file to find the right audio track (stereo)
# to use to transcode the file into the proper format (flv).
# Parameters: The following parameters are required in the following
# order:
#	- Input File: File that will be transcoded into FLV format
#	- Seek Position: In seconds, the position of the video for
#		which the encode will begin
#	- Bitrate: The bitrate to use to encode the video file
#	- Width: The desired horizontal resolution of the encoded
#		video file
#	- Height: The desired vertical resolution of the encoded
#		video file

LOGFILE=/var/subsonic/transcode.log

FILE=$1
echo "File: $FILE" >> $LOGFILE
if [ "$FILE" = "" ]; then
	echo "Insufficient Parameters: Missing input file."
	exit 1
fi

SEEK=$2
echo "Seek Position: $SEEK" >> $LOGFILE
if [ "$SEEK" = "" ]; then
	echo "Insufficient Parameters: Missing seek position."
	exit 1
fi

BITRATE=$3
echo "Bit Rate: $BITRATE" >> $LOGFILE
if [ "$BITRATE" = "" ]; then
	echo "Insufficient Parameters: Missing bitrate."
	exit 1
fi

WIDTH=$4
echo "Horizontal Resolution: $WIDTH" >> $LOGFILE
if [ "$WIDTH" = "" ]; then
	echo "Insufficient Parameters: Missing horizontal resolution."
	exit 1
fi

HEIGHT=$5
echo "Vertical Resolution: $HEIGHT" >> $LOGFILE
if [ "$HEIGHT" = "" ]; then
	echo "Insufficient Parameters: Missing vertical resolution."
	exit 1
fi

AUDIO_REGEX='^    Stream #[0-9]+\.([0-9]+)\([^\)]+\): Audio: ([^,]+), ([0-9]+) Hz, (.+)$'

FILE_INFO=$(ffmpeg -i "$FILE" 2>&1)
if [ "$FILE_INFO" != "" ]; then
	echo "File Information: $FILE_INFO" >> $LOGFILE
	STEREO_INFO=$(echo "$FILE_INFO" | grep '^    Stream' | grep 'stereo')
	echo "Stereo Track Information: $STEREO_INFO" >> $LOGFILE
	if [[ $STEREO_INFO =~ $AUDIO_REGEX ]]; then
		STEREO_STREAM=${BASH_REMATCH[1]}
		echo "Successfully located the stereo audio stream: #0.${BASH_REMATCH[1]}" >> $LOGFILE
		echo "Issuing transcoding command: ffmpeg -ss $SEEK -i "$FILE" -b ${BITRATE}k -s ${WIDTH}x${HEIGHT} -vcodec flv -map 0.0 -acodec libmp3lame -async 1 -ar 44100 -map 0.${STEREO_STREAM} -v 0 -f flv -" >> $LOGFILE
		ffmpeg -ss $SEEK -i "$FILE" -b ${BITRATE}k -s ${WIDTH}x${HEIGHT} -vcodec flv -map 0.0 -acodec libmp3lame -async 1 -ar 44100 -map 0.${STEREO_STREAM} -v 0 -f flv -
	fi
fi
