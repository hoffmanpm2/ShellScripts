#!/bin/bash

MOVIE_SECTION_URL=http://ladon:32400/library/sections/1/resolution/480
MEDIA_REGEX='^<Media id="([0-9]+)" .+ aspectRatio="1.33"'

# Loop through XML elements
while read ELEMENT
do
   # The Media element contains the aspect ratio of the video
   if [[ $ELEMENT =~ $MEDIA_REGEX ]];
   then
      MEDIA_ID=${BASH_REMATCH[1]}
		VIDEO_REGEX1="^<Video ratingKey=\"${MEDIA_ID}\" .+ title=\"(.+)\" titleSort"
		VIDEO_REGEX2="^<Video ratingKey=\"${MEDIA_ID}\" .+ title=\"(.+)\" contentRating"
		VIDEO_REGEX3="^<Video ratingKey=\"${MEDIA_ID}\" .+ title=\"(.+)\" summary"
      while read VIDEO_ELEMENT
      do
			if [[ $VIDEO_ELEMENT =~ $VIDEO_REGEX1  ||
				$VIDEO_ELEMENT =~ $VIDEO_REGEX2 ||
				$VIDEO_ELEMENT =~ $VIDEO_REGEX3 ]];
			then
				TITLE=${BASH_REMATCH[1]}

				# Replace &quot; with '
				TITLE=${TITLE//&quot;/\"}      

				# Replace &amp; with '
				TITLE=${TITLE//&amp;/\&}      

				# Replace &apos; with '
				TITLE=${TITLE//&apos;/\'}      

				# Replace &lt; with '
				TITLE=${TITLE//&lt;/<}      

				# Replace &gt; with '
				TITLE=${TITLE//&gt;/>}

				echo $TITLE
			fi
		done <<< "$(curl -Ss $MOVIE_SECTION_URL)"
   fi
done <<< "$(curl -Ss $MOVIE_SECTION_URL)"

