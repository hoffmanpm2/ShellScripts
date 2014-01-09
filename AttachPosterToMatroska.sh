#!/bin/bash

INPUT=$1
INPUTFILE=$(basename "${INPUT}")
OUTPUTFILE=${INPUTFILE%.*}.mkv
OUTPUTPATH=/home/philip/Media/Video/Movies/MKV
OUTPUT=$OUTPUTPATH/$OUTPUTFILE

if [ -f "${OUTPUT}" ]; then
	mkvpropedit --attachment-mime-type image/jpeg --add-attachment "${INPUT}" "${OUTPUT}"
else
	echo "ERROR: Could not find ${OUTPUT}."
fi
