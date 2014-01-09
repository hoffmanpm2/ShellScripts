#!/bin/bash
# FixMKVSubs
# RULE 1: English subtitle tracks without forced subtitles should not have default flag checked.
# RULE 2: English subtitle tracks with forced subtitles should have the forced & default flags checked.
# RULE 3: If the language for the primary audio track is not English, there should be a single subtitle
# track & it should have the forced & default flags checked. I believe XBMC will automatically
# select the first subtitle track regardless of state of the default flag. If this is not true,
# then this rule can be amended to only check the default flag.
# RULE 4: There should only be a single subtitle track unless one track has the forced flag checked.
# RULE 5: If the forced flag is checked, the default flag should also be checked.

FILE=$1
FFMPEG_BIN=/home/philip/Projects/BASH/ConvertMKV2MP4/ffmpeg

if [ -f "${FILE}" ]; then
	MKV_INFO=$($FFMPEG_BIN -i "${FILE}" 2>&1)
	AUDIO_PRIMARY_INFO=$(echo "${MKV_INFO}" | grep '^    Stream #0:1')
	AUDIO_PRIMARY_REGEX='^    Stream #0:1\(([^\)]+)\): Audio: .+$'

	if [[ $AUDIO_PRIMARY_INFO =~ $AUDIO_PRIMARY_REGEX ]]; then
		AUDIO_PRIMARY_LANG=${BASH_REMATCH[1]}
		SUBTITLE_TRACKS_INFO=$(echo "${MKV_INFO}" | grep '^    Stream' | grep 'Subtitle:')
		for SUBTITLE_TRACK in ${SUBTITLE_TRACKS_INFO}
		do
			echo "${SUBTITLE_TRACK}"
			SUBTITLE_REGEX='^    Stream #[0-9]+:([0-9]+)\(([^\)]+)\): Subtitle'
			if [ -z "${SUBTITLE_PRIMARY_INFO}" ]; then
				SUBTITLE_PRIMARY_INFO=$(echo "${SUBTITLE_TRACK}")
				if [[ $SUBTITLE_PRIMARY_INFO =~ $SUBTITLE_REGEX ]]; then
					SUBTITLE_PRIMARY_TRACK=${BASH_REMATCH[1]}
					SUBTITLE_PRIMARY_LANG=${BASH_REMATCH[2]}
				fi
			else
				SUBTITLE_SECONDARY_INFO=$(echo "${SUBTITLE_TRACK}")
				if [[ $SUBTITLE_SECONDARY_INFO =~ $SUBTITLE_REGEX ]]; then
					SUBTITLE_SECONDARY_TRACK=${BASH_REMATCH[1]}
					SUBTITLE_SECONDARY_LANG=${BASH_REMATCH[2]}
				fi
			fi
			echo Yo
		done

		echo Subtitle \#1: Track \#$SUBTITLE_PRIMARY_TRACK \($SUBTITLE_PRIMARY_LANG\)
		echo Subtitle \#2: Track \#$SUBTITLE_SECONDARY_TRACK \($SUBTITLE_SECONDARY_LANG\)
	fi
fi

