#!/bin/bash

# File: rotguard.sh
# Author: Philip M. Hoffman II
# Description: Checksums & verifies files & mtimes to verify files have not
#    been affected by bit rot.
# Requisites: Directory to scan or file to checksum/verify.

# For loop supporting wildcard expansion
for FILE in $(ls $1)
do
   ######
   # Step 1: Create/Retrieve the time $FILE was last modified.
   #
   # 1A: If it exists, retrieve the value stored in user.time.modified. This value
   #     represents the time $FILE was last modified. Create if it does not exist.
   if ! MTIME=$(getfattr -n user.time.modified $FILE --only-values 2>/dev/null)
   then
      echo [ $(date +"%T %Y %b %d") ] - INFO: ${FILE##*/} - xattr, user.time.modified, not found
      if setfattr -n user.time.modified -v "$(stat -c %Y $FILE)" $FILE
      then
         MTIME=$(getfattr -n user.time.modified $FILE --only-values 2>/dev/null)
      else
         echo [ $(date +"%T %Y %b %d") ] - ERROR: Could not create the extended attribute, user.time.modified, for $FILE >2
         exit 1
      fi
   fi

   ######
   # Step 2: Create/Retrieve the checksum for $FILE
   #
   # 2A: If it exists, retrieve the value stored in user.checksum.md5. This value
   #     represents a checksum of $FILE & will be used to verify its status.
   #     Create if it does not exist.
   if ! MD5=$(getfattr -n user.checksum.md5 $FILE --only-values 2>/dev/null)
   then

      # 2A/1: Create user.checksum.md5 extended attribute & populate it with
      #       a fresh checksum.
      echo [ $(date +"%T %Y %b %d") ] - INFO: ${FILE##*/} - xattr, user.checksum.md5, not found
      if setfattr -n user.checksum.md5 -v "$(md5sum $FILE)" $FILE
      then
         MD5=$(getfattr -n user.checksum.md5 $FILE --only-values 2>/dev/null)
      else
         echo [ $(date +"%T %Y %b %d") ] - ERROR: Could not create the extended attribute, user.checksum.md5, for $FILE >2
         exit 1
      fi

   ###
   # 2B: The extended attribute user.checksum.md5 exists. The file $FILE should be
   #     validated against the checksum. If it differs & the value stored in $MTIME
   #     is equal to the current mtime then the file $FILE is suspect. Otherwise,
   #     a new checksum should be generated & the file should update both extended
   #     attributes with the new values.
   else
      # 2B/1: Validate the checksum. If the checksums match there is nothing to
      #       be done. Otherwise, proceed to comparing the current mtime to $MTIME
      if ! $(echo $MD5 | md5sum --quiet -c -)
      then
         # 2B/2: Compare the current mtime to $MTIME. If they do not match then
         #       the file has been modified & we should generate a new checksum.
         #       Then we should write the $MTIME and new checksum to the
         #       extended attributes. This can be accomplished by removing the
         #       extended attributes in $FILE and calling this script again.
         if [ $MTIME != $(stat -c %Y $FILE) ]
         then
            echo [ $(date +"%T %Y %b %d") ] - INFO: ${FILE##*/} - mtime values are different.
            setfattr -x user.checksum.md5 $FILE
            setfattr -x user.time.modified $FILE
            $0 $FILE

         # 2B/3: The files have been compared & the file has failed validation.
         #       The current mtime value matches $MTIME which indicates that
         #       this file could possibly be corrupt & should be marked as
         #       suspect. 
         #
         #       We could do a lot of things to indicate that a file is suspect.
         #       We could email the owner when we find a suspect file. We could
         #       add the file to a file containing suspect video files & email
         #       the list to others periodically. We could also move suspect
         #       videos to a sandbox area to remove them from circulation. We
         #       could also do all of these things.
         else
            echo [ $(date +"%T %Y %b %d") ] - WARN: ${FILE##*/} - mtime values are equivalent.
				echo "<html><body>The integrity of the following file has been determined to be suspect:<br><br>${FILE##*/}<br><br>
It has been hidden and will not be detected by Plex.</body></html>" | mailx -s "Suspect File" itsthesource@gmail.com
            #OWNER=$(stat -c %U $FILE)   # Retrieves owner (name) of $FILE
            #GECOS=$(grep "^${OWNER}*" /etc/passwd | awk -F : '{print $5}')   #Retrieves GECOS field for owner
            #if [ -z "${GECOS}" ]
            #then
               # 2B/3A: Parse the GECOS file in search of the owner's email
               #        address. In conjunction with mailx, we can use this
               #        to notify the owner of the problem.
               #for FIELD in $(echo $GECOS | sed s/,/\\n/g)
               #do
               #   if [[ $FIELD =~ "^[_A-Za-z0-9-]+(\\.[_A-Za-z0-9-]+)*@[A-Za-z0-9]+(\\.[A-Za-z0-9]+)*(\\.[A-Za-z]{2,})$" ]]
               #   then
               #		Send an email to the owner's email address
               #   fi
               #done
            #fi

            # 2B/3B: Create the sandbox if it does not exist & move the
            #        file into it. This new location should not be
            #        accessible by Plex or any other software.
            if ! $(mv $FILE ${FILE%/*}/.${FILE##*/})
            then
               echo [ $(date +"%T %Y %b %d") ] - ERROR: Unable to sandbox $FILE
               exit 1
            else
               echo [ $(date +"%T %Y %b %d") ] - INFO: ${FILE##*/} has been hidden to prevent it from being detected by Plex
            fi
         fi
      else
         echo [ $(date +"%T %Y %b %d") ] - INFO: ${FILE##*/} - Validation successful.
      fi
   fi
done
