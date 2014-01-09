#!/bin/bash

string="/home/philip/Media/Video/TV Shows/Sci Fi/Star Trek - The Next Generation/Season 1/Ep. 03 - The Naked Now.m4v";

if [[ $string == */TV\ Shows/* ]]
then
	while IFS='/' read -ra MEDIA; do
		echo "${MEDIA[7]} ${MEDIA[8]}.jpg"
		for i in "${MEDIA[@]}"; do
			echo "> $i";
		done
	done <<< $string
fi
