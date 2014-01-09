#!/bin/bash

FILE=$1
FILENAME=$(basename "${FILE}")
FILEPATH=$(dirname "${FILE}")
SRT_EXT=${FILENAME%.*}.en.srt
SUB_EXT=${FILENAME%.*}.sub
PGS_EXT=${FILENAME%.*}.sup

if [ -f "${FILE}" ]; then
	MKV_INFO=$(mkvmerge -i "${FILE}" 2>&1)
	SUBTITLE_INFO=$(echo "${MKV_INFO}" | grep 'subtitles')
	SUBTITLES_SRT_REGEX='^Track ID ([0-9]+): subtitles \(S_TEXT/UTF-8\)'
	SUBTITLES_SUB_REGEX='^Track ID ([0-9]+): subtitles \(S_VOBSUB\)'
	SUBTITLES_PGS_REGEX='^Track ID ([0-9]+): subtitles \(S_HDMV/PGS\)'

	if [[ $SUBTITLE_INFO =~ $SUBTITLES_SRT_REGEX ]]; then
		if [ ! -f "${FILEPATH}/${SRT_EXT}" ]; then
			mkvextract tracks "${FILE}" ${BASH_REMATCH[1]}:"${FILEPATH}/${SRT_EXT}"
		fi

	elif [[ $SUBTITLE_INFO =~ $SUBTITLES_SUB_REGEX ]]; then
		if [ ! -f "${FILEPATH}/${SUB_EXT}" ] && [ ! -f "${FILEPATH}/${SRT_EXT}" ]; then
			mkvextract tracks "${FILE}" ${BASH_REMATCH[1]}:"${FILEPATH}/${SUB_EXT}"
		fi

	elif [[ $SUBTITLE_INFO =~ $SUBTITLES_PGS_REGEX ]]; then
		if [ ! -f "${FILEPATH}/${PGS_EXT}" ] && [ ! -f "${FILEPATH}/${SRT_EXT}" ]; then
			mkvextract tracks "${FILE}" ${BASH_REMATCH[1]}:"${FILEPATH}/${PGS_EXT}"
		fi
	fi
fi

