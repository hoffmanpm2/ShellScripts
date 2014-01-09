#!/bin/bash
#
# Description: Transfers a movie from one user to another user.
#    It will also transfer the poster art from one media folder
#    to another so the PS3 will continue to see movie posters.
#
# Inputs:
#    Path to Movie File
#    User Name

# Check for root privileges. If we use chown to change the owner
# of our media files, then we will need to have root privileges.
if [ $(id -u) -ne 0 ]; then
    echo "ERROR: Insufficient privileges. Must run as root."
    exit 1
fi

MEDIAFILE=$(basename "$2")									# OK
POSTERFILE=$MEDIAFILE.jpg									# OK
OLDMEDIAPATH=$(dirname "$2")									# OK
NEWMEDIAPATH=$(dirname "$(getent passwd $1 | cut -d: -f6)/${2#/Media*}")			# OK (Parameter Expansion)
OLDPOSTERPATH="$(echo ${2%/Video*})/Posters"							# OK (Parameter Expansion)
NEWPOSTERPATH="$(find $(getent passwd $1 | cut -d: -f6) -type d -iname posters 2>/dev/null)"	# OK

echo FILE: $MEDIAFILE
echo POSTER: $(pwd)/$OLDPOSTERPATH/$POSTERFILE
echo NEW POSTER: $NEWPOSTERPATH/$POSTERFILE
echo PATH: $(pwd)/$OLDMEDIAPATH/$MEDIAFILE
echo NEW PATH: $NEWMEDIAPATH/$MEDIAFILE
echo

# Echo media file to be transferred (minus path)
#

# Move the poster art to the new location. Upon success display
# output in the following format: old_file > new_file. On failure,
# display a suitable error message and terminate.
#
# NOTE: This script should handle the possibility that there is no
# poster art for this file. Television shows have a single poster
# for the entire season. This script must account for this as well.
# mv "$OLDPOSTERPATH/$POSTERFILE" "$NEWPOSTERPATH/$POSTERFILE"

# Move the media file to the new location. Upon success display
# output in the following format: old_file > new_file. On failure,
# display a suitable error message and terminate.
#
# NOTE: We must consider changing the ownership of the media file
# to the new user. This may require the script to be run with root
# priviliges.
# mv "$(pwd)/$OLDMEDIAPATH/$MEDIAFILE" "$NEWMEDIAPATH/$MEDIAFILE"

