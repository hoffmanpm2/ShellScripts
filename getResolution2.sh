#!/bin/bash

input='  Duration: 02:06:17.57, start: 0.000000, bitrate: 1902 kb/s
    Stream #0.0(und): Video: h264, yuv420p, 716x480 [PAR 32:27 DAR 716:405], 1737 kb/s, 23.99 fps, 23.98 tbr, 90k tbn, 47.95 tbc
    Stream #0.1(eng): Audio: aac, 48000 Hz, stereo, s16, 159 kb/s
    Stream #0.2(und): Subtitle: text / 0x74786574'

duration_line=`echo "$input" | grep '^  Duration'`
audio_line=`echo "$input" | grep '^    Stream' | grep 'Audio'`
video_line=`echo "$input" | grep '^    Stream' | grep 'Video'`

echo $duration_line
echo $audio_line
echo $video_line

duration_regex='^  Duration: ([0-9]+:[0-9]+:[0-9]+\.[0-9]+), start: [0-9]+\.[0-9]+, bitrate: ([0-9]+) kb/s$'
audio_regex='^    Stream #[0-9]+\.[0-9]+\([^\)]+\): Audio: ([^,]+), ([0-9]+) Hz, (.+)$'
video_regex='^    Stream #[0-9]+\.[0-9]+\(.+\): Video: (.+), (.+), ([0-9]+x[0-9]+) \[PAR [0-9]+:[0-9]+ DAR [0-9]+:[0-9]+\], ([0-9]+) kb/s, ([0-9]+\.[0-9]+) fps, (.+)$'

if [[ $duration_line =~ $duration_regex ]]
then
duration=${BASH_REMATCH[1]}
bitrate=${BASH_REMATCH[2]}
else
echo 'failed to match duration line'
fi

if [[ $audio_line =~ $audio_regex ]]
then
audio_format=${BASH_REMATCH[1]}
audio_hz=${BASH_REMATCH[2]}
audio_type=${BASH_REMATCH[3]}
else
echo 'failed to match audio line'
fi

if [[ $video_line =~ $video_regex ]]
then
video_format=${BASH_REMATCH[1]}
video_type=${BASH_REMATCH[2]}
video_dimensions=${BASH_REMATCH[3]}
video_bitrate=${BASH_REMATCH[4]}
video_fps=${BASH_REMATCH[5]}
else
echo 'failed to match video line'
fi


echo $duration
echo $bitrate
echo $audio_format
echo $audio_hz
echo $audio_type
echo $video_format
echo $video_type
echo $video_dimensions
echo $video_bitrate
echo $video_fps
