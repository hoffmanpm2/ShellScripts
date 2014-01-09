#!/bin/bash
#Author: Philip Hoffman
#Description: Finds files that do not have the proper
#file permissions.

#Change video permissions
PERM=755
FILTER=*.m3u
find $HOME/Media/Video -not -perm $PERM -not -iname $FILTER -type f -exec chmod $PERM {} \;
find $HOME/Media/Video -not -perm $PERM -type d -exec chmod $PERM {} \;

#Change poster permissions
FILTER=FFMPEG*
find $HOME/Media/Posters -not -perm $PERM -not -iname $FILTER -type f -exec chmod $PERM {} \;

#Change user/group ownerships
USER=$(whoami)
GROUP=users
find $HOME/Media/Posters -not -user $USER -or -not -group $GROUP -exec chown $USER.$GROUP {} \;
find $HOME/Media/Video -not -user $USER -or -not -group $GROUP -exec chown $USER.$GROUP {} \;
