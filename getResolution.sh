#!/bin/bash

find Media/Video/Movies -iname *.* -type f | while read FILE;
do
	VIDEO_INFO=$(ffmpeg -i "$FILE" 2>&1 | grep '^    Stream' | grep 'Video');
	video_regex='^    Stream #[0-9]+\.[0-9]+\(.+\): Video: (.+), (.+), ([0-9]+x[0-9]+) \[PAR [0-9]+:[0-9]+ DAR [0-9]+:[0-9]+\], ([0-9]+) kb/s, ([0-9]+\.[0-9]+) fps, (.+)$'
	if [[ $VIDEO_INFO =~ $video_regex ]]; then
		RES=(`echo ${BASH_REMATCH[3]} | tr 'x', ' '`)
		echo $FILE
		echo Horizontal Resolution: ${RES[0]}
		echo Vertical Resolution: ${RES[1]}
	fi
done
