#! /bin/bash
# This script renames files using the following rules:
#	Rule 1: Files newer than 30 days ago & High Definition, rename "(HD).mp4" to "(HD,+).mp4"
#	Rule 2: Files newer than 30 days ago & Standard Definition, rename ".m4v" to " (+).m4v"

find /home/philip/Media/Video -iname *+\).* -daystart -mtime +30 -type f | while read FILE;
do
	EXT=${FILE##*.};
	FILENAME=${FILE##*/}.jpg;
	POSTERPATH="/home/philip/Media/Posters/";
	if [ "$EXT" != "mp4" ]; then
		if [ -a "$POSTERPATH$FILENAME" ]; then
			rename " (+).$EXT" ".$EXT" "$POSTERPATH$FILENAME";
		fi
		rename " (+).$EXT" ".$EXT" "$FILE";
	else
		HD=${FILE##*(HD};
		if [ "$HD" == "$FILE" ]; then
			if [ -a "$POSTERPATH$FILENAME" ]; then
				rename " (+).$EXT" ".$EXT" "$POSTERPATH$FILENAME";
			fi
			rename " (+).$EXT" ".$EXT" "$FILE";
		else
			if [ -a "$POSTERPATH$FILENAME" ]; then
				rename "(HD,+)" "(HD)" "$POSTERPATH$FILENAME";
			fi
			rename "(HD,+)" "(HD)" "$FILE";
		fi
	fi
done
