#!/bin/bash
#
# @author   Bram van Oploo
# @date     2012-10-06
# @version  2.6.0
#

NAME="Plex Home Theater"
PLEX_USER="plex"
THIS_FILE=$0
SCRIPT_VERSION="2.6.0"
VIDEO_DRIVER=""
HOME_DIRECTORY="/home/$PLEX_USER/"
TEMP_DIRECTORY=$HOME_DIRECTORY"temp/"
ENVIRONMENT_FILE="/etc/environment"
CRONTAB_FILE="/etc/crontab"
DIST_UPGRADE_FILE="/etc/cron.d/dist_upgrade.sh"
DIST_UPGRADE_LOG_FILE="/var/log/updates.log"
PLEX_INIT_FILE="/etc/init.d/plexhometheater"
PLEX_ADDONS_DIR=$HOME_DIRECTORY".plexht/addons/"
PLEX_USERDATA_DIR=$HOME_DIRECTORY".plexht/userdata/"
PLEX_KEYMAPS_DIR=$PLEX_USERDATA_DIR"keymaps/"
PLEX_ADVANCEDSETTINGS_FILE=$PLEX_USERDATA_DIR"advancedsettings.xml"
PLEX_INIT_CONF_FILE="/etc/init/plexht.conf"
PLEX_XSESSION_FILE=$HOME_DIRECTORY".xsession"
PLEX_CUSTOM_EXEC="/usr/bin/plexhometheater.sh"
UPSTART_JOB_FILE="/lib/init/upstart-job"
XWRAPPER_FILE="/etc/X11/Xwrapper.config"
GRUB_CONFIG_FILE="/etc/default/grub"
GRUB_HEADER_FILE="/etc/grub.d/00_header"
SYSTEM_LIMITS_FILE="/etc/security/limits.conf"
INITRAMFS_SPLASH_FILE="/etc/initramfs-tools/conf.d/splash"
INITRAMFS_MODULES_FILE="/etc/initramfs-tools/modules"
XWRAPPER_CONFIG_FILE="/etc/X11/Xwrapper.config"
MODULES_FILE="/etc/modules"
REMOTE_WAKEUP_RULES_FILE="/etc/udev/rules.d/90-enable-remote-wakeup.rules"
AUTO_MOUNT_RULES_FILE="/etc/udev/rules.d/media-by-label-auto-mount.rules"
SYSCTL_CONF_FILE="/etc/sysctl.conf"
POWERMANAGEMENT_DIR="/var/lib/polkit-1/localauthority/50-local.d/"
DOWNLOAD_URL="https://github.com/Bram77/xbmc-ubuntu-minimal/raw/master/12.10/download/"
PLEX_PPA="ppa:plexapp/plexht"
FFMPEG_PPA="ppa:jon-severinsson/ffmpeg"
LCEC_PPA="ppa:pulse-eight/libcec"
HTS_TVHEADEND_PPA="ppa:jabbors/hts-stable"
OSCAM_PPA="ppa:oscam/ppa"
PLEX_INIT_URL="http://www.dropbox.com/s/1su2d29ztub3kvx/plexhometheater"

LOG_FILE=$HOME_DIRECTORY"plexht_installation.log"
DIALOG_WIDTH=70
SCRIPT_TITLE="XBMC installation script v$SCRIPT_VERSION for Ubuntu 12.10 by Bram van Oploo :: bram@sudo-systems.com :: www.sudo-systems.com"

GFX_CARD=$(lspci |grep VGA |awk -F: {' print $3 '} |awk {'print $1'} |tr [a-z] [A-Z])

## ------ START functions ---------

function showInfo()
{
    CUR_DATE=$(date +%Y-%m-%d" "%H:%M)
    echo "$CUR_DATE - INFO :: $@" >> $LOG_FILE
    dialog --title "Installing & configuring..." --backtitle "$SCRIPT_TITLE" --infobox "\n$@" 5 $DIALOG_WIDTH
}

function showError()
{
    CUR_DATE=$(date +%Y-%m-%d" "%H:%M)
    echo "$CUR_DATE - ERROR :: $@" >> $LOG_FILE
    dialog --title "Error" --backtitle "$SCRIPT_TITLE" --msgbox "$@" 8 $DIALOG_WIDTH
}

function showDialog()
{
	dialog --title "${NAME} installation script" \
		--backtitle "$SCRIPT_TITLE" \
		--msgbox "\n$@" 12 $DIALOG_WIDTH
}

function update()
{
    sudo apt-get update > /dev/null 2>&1
}

function createFile()
{
    FILE="$1"
    IS_ROOT="$2"
    REMOVE_IF_EXISTS="$3"
    
    if [ -e "$FILE" ] && [ "$REMOVE_IF_EXISTS" == "1" ]; then
        sudo rm "$FILE" > /dev/null
    else
        if [ "$IS_ROOT" == "0" ]; then
            touch "$FILE" > /dev/null
        else
            sudo touch "$FILE" > /dev/null
        fi
    fi
}

function createDirectory()
{
    DIRECTORY="$1"
    GOTO_DIRECTORY="$2"
    IS_ROOT="$3"
    
    if [ ! -d "$DIRECTORY" ];
    then
        if [ "$IS_ROOT" == "0" ]; then
            mkdir -p "$DIRECTORY" > /dev/null 2>&1
        else
            sudo mkdir -p "$DIRECTORY" > /dev/null 2>&1
        fi
    fi
    
    if [ "$GOTO_DIRECTORY" == "1" ];
    then
        cd $DIRECTORY
    fi
}

function handleFileBackup()
{
    FILE="$1"
    BACKUP="$1.bak"
    IS_ROOT="$2"
    DELETE_ORIGINAL="$3"

    if [ -e "$BACKUP" ];
	then
	    if [ "$IS_ROOT" == "1" ]; then
	        sudo rm "$FILE" > /dev/null 2>&1
		    sudo cp "$BACKUP" "$FILE" > /dev/null 2>&1
	    else
		    rm "$FILE" > /dev/null 2>&1
		    cp "$BACKUP" "$FILE" > /dev/null 2>&1
		fi
	else
	    if [ "$IS_ROOT" == "1" ]; then
		    sudo cp "$FILE" "$BACKUP" > /dev/null 2>&1
		else
		    cp "$FILE" "$BACKUP" > /dev/null 2>&1
		fi
	fi
	
	if [ "$DELETE_ORIGINAL" == "1" ]; then
	    sudo rm "$FILE" > /dev/null 2>&1
	fi
}

function appendToFile()
{
    FILE="$1"
    CONTENT="$2"
    IS_ROOT="$3"
    
    if [ "$IS_ROOT" == "0" ]; then
        echo "$CONTENT" | tee -a "$FILE" > /dev/null 2>&1
    else
        echo "$CONTENT" | sudo tee -a "$FILE" > /dev/null 2>&1
    fi
}

function addRepository()
{
    REPOSITORY=$@
    KEYSTORE_DIR=$HOME_DIRECTORY".gnupg/"
    createDirectory "$KEYSTORE_DIR" 0 0
    sudo add-apt-repository -y $REPOSITORY > /dev/null 2>&1

    if [ "$?" == "0" ]; then
        update
        showInfo "$REPOSITORY repository successfully added"
        echo 1
    else
        showError "Repository $REPOSITORY could not be added (error code $?)"
        echo 0
    fi
}

function isPackageInstalled()
{
    PACKAGE=$@
    sudo dpkg-query -l $PACKAGE > /dev/null 2>&1
    
    if [ "$?" == "0" ]; then
        echo 1
    else
        echo 0
    fi
}

function aptInstall()
{
    PACKAGE=$@
    IS_INSTALLED=$(isPackageInstalled $PACKAGE)

    if [ "$IS_INSTALLED" == "1" ]; then
        showInfo "Skipping installation of $PACKAGE. Already installed."
        echo 1
    else
        sudo apt-get -f install > /dev/null 2>&1
        sudo apt-get -y install $PACKAGE > /dev/null 2>&1
        
        if [ "$?" == "0" ]; then
            showInfo "$PACKAGE successfully installed"
            echo 1
        else
            showError "$PACKAGE could not be installed (error code: $?)"
            echo 0
        fi 
    fi
}

function download()
{
    URL="$@"
    wget -q "$URL" > /dev/null 2>&1
}

function move()
{
    SOURCE="$1"
    DESTINATION="$2"
    IS_ROOT="$3"
    
    if [ -e "$SOURCE" ];
	then
	    if [ "$IS_ROOT" == "0" ]; then
	        mv "$SOURCE" "$DESTINATION" > /dev/null 2>&1
	    else
	        sudo mv "$SOURCE" "$DESTINATION" > /dev/null 2>&1
	    fi
	    
	    if [ "$?" == "0" ]; then
	        echo 1
	    else
	        showError "$SOURCE could not be moved to $DESTINATION (error code: $?)"
	        echo 0
	    fi
	else
	    showError "$SOURCE could not be moved to $DESTINATION because the file does not exist"
	    echo 0
	fi
}

------------------------------

function installDependencies()
{
    echo "-- Installing installation dependencies..."
    echo ""

	sudo apt-get -y install dialog software-properties-common > /dev/null 2>&1
}

function fixLocaleBug()
{
    createFile $ENVIRONMENT_FILE
    handleFileBackup $ENVIRONMENT_FILE 1
    appendToFile $ENVIRONMENT_FILE "LC_MESSAGES=\"C\""
    appendToFile $ENVIRONMENT_FILE "LC_ALL=\"en_US.UTF-8\""
	showInfo "Locale environment bug fixed"
}

function fixUsbAutomount()
{
    handleFileBackup "$MODULES_FILE" 1 1
    appendToFile $MODULES_FILE "usb-storage"
    createDirectory "$TEMP_DIRECTORY" 1 0
    download $DOWNLOAD_URL"media-by-label-auto-mount.rules"

    if [ -e $TEMP_DIRECTORY"media-by-label-auto-mount.rules" ]; then
	    IS_MOVED=$(move $TEMP_DIRECTORY"media-by-label-auto-mount.rules" "$AUTO_MOUNT_RULES_FILE")
	    showInfo "USB automount successfully fixed"
	else
	    showError "USB automount could not be fixed"
	fi
}

function applyPlexNiceLevelPermissions()
{
	createFile $SYSTEM_LIMITS_FILE
    appendToFile $SYSTEM_LIMITS_FILE "$PLEX_USER             -       nice            -1"
	showInfo "Allowed ${NAME} to prioritize threads"
}

function addUserToRequiredGroups()
{
	sudo adduser $PLEX_USER video > /dev/null 2>&1
	sudo adduser $PLEX_USER audio > /dev/null 2>&1
	sudo adduser $PLEX_USER users > /dev/null 2>&1
	sudo adduser $PLEX_USER fuse > /dev/null 2>&1
	sudo adduser $PLEX_USER cdrom > /dev/null 2>&1
	sudo adduser $PLEX_USER plugdev > /dev/null 2>&1
	showInfo "${NAME} user added to required groups"
}

function addPlexPpa()
{
    showInfo "Adding ${NAME} PPA..."
	IS_ADDED=$(addRepository "$PLEX_PPA")
    showInfo "Adding FFMpeg PPA..."
	IS_ADDED=$(addRepository "$FFMPEG_PPA")
    showInfo "Adding libcec PPA..."
	IS_ADDED=$(addRepository "$LCEC_PPA")
}

function distUpgrade()
{
    showInfo "Updating Ubuntu with latest packages (may take a while)..."
	update
	sudo apt-get -y dist-upgrade > /dev/null 2>&1
	showInfo "Ubuntu installation updated"
}

function installXinit()
{
    showInfo "Installing xinit..."
    IS_INSTALLED=$(aptInstall xinit)
}

#function installPowerManagement()
#{
#    showInfo "Installing power management packages..."
#    createDirectory "$TEMP_DIRECTORY" 1 0
#    IS_INSTALLED=$(aptInstall policykit-1)
#    IS_INSTALLED=$(aptInstall upower)
#    IS_INSTALLED=$(aptInstall udisks)
#    IS_INSTALLED=$(aptInstall acpi-support)
#	download $DOWNLOAD_URL"custom-actions.pkla"
#	createDirectory "$POWERMANAGEMENT_DIR"
#    IS_MOVED=$(move $TEMP_DIRECTORY"custom-actions.pkla" "$POWERMANAGEMENT_DIR")
#}

function installAudio()
{
    showInfo "Installing audio packages....\n!! Please make sure no used channels are muted !!"
    IS_INSTALLED=$(aptInstall linux-sound-base)
    IS_INSTALLED=$(aptInstall alsa-base)
    IS_INSTALLED=$(aptInstall alsa-utils)
    IS_INSTALLED=$(aptInstall libasound2)
    sudo alsamixer
}

function installLirc()
{
    clear
    echo ""
    echo "Installing lirc..."
    echo ""
    echo "------------------"
    echo ""
    
	sudo apt-get -y install lirc
	
	if [ "$?" == "0" ]; then
        showInfo "Lirc successfully installed"
    else
        showError "Lirc could not be installed (error code: $?)"
    fi
}

function allowRemoteWakeup()
{
    showInfo "Allowing for remote wakeup (won't work for all remotes)..."
	createDirectory "$TEMP_DIRECTORY" 1 0
	handleFileBackup "$REMOTE_WAKEUP_RULES_FILE" 1 1
	download $DOWNLOAD_URL"remote_wakeup_rules"
	
	if [ -e $TEMP_DIRECTORY"remote_wakeup_rules" ]; then
	    sudo mv $TEMP_DIRECTORY"remote_wakeup_rules" "$REMOTE_WAKEUP_RULES_FILE" > /dev/null 2>&1
	    showInfo "Remote wakeup rules successfully applied"
	else
	    showError "Remote wakeup rules could not be downloaded"
	fi
}

function installPlex()
{
    showInfo "Installing ${NAME}..."
    IS_INSTALLED=$(aptInstall plexhometheater)
}

function enableDirtyRegionRendering()
{
    showInfo "Enabling ${NAME} dirty region rendering..."
	createDirectory "$TEMP_DIRECTORY" 1 0
	handleFileBackup $PLEX_ADVANCEDSETTINGS_FILE 0 1
	download $DOWNLOAD_URL"dirty_region_rendering.xml"
	createDirectory "$PLEX_USERDATA_DIR" 0 0
	IS_MOVED=$(move $TEMP_DIRECTORY"dirty_region_rendering.xml" "$PLEX_ADVANCEDSETTINGS_FILE")

	if [ "$IS_MOVED" == "1" ]; then
        showInfo "${NAME} dirty region rendering enabled"
    else
        showError "${NAME} dirty region rendering could not be enabled"
    fi
}

function configureAtiDriver()
{
    sudo aticonfig --initial -f > /dev/null 2>&1
    sudo aticonfig --sync-vsync=on > /dev/null 2>&1
    sudo aticonfig --set-pcs-u32=MCIL,HWUVD_H264Level51Support,1 > /dev/null 2>&1
}

function disbaleAtiUnderscan()
{
	sudo kill $(pidof X) > /dev/null 2>&1
	sudo aticonfig --set-pcs-val=MCIL,DigitalHDTVDefaultUnderscan,0 > /dev/null 2>&1
    showInfo "Underscan successfully disabled"
}

function enableAtiUnderscan()
{
	sudo kill $(pidof X) > /dev/null 2>&1
	sudo aticonfig --set-pcs-val=MCIL,DigitalHDTVDefaultUnderscan,1 > /dev/null 2>&1
    showInfo "Underscan successfully enabled"
}

function installVideoDriver()
{
    showInfo "Installing $GFX_CARD video drivers (may take a while)..."
    
    if [[ $GFX_CARD == NVIDIA ]]; then
        VIDEO_DRIVER="nvidia-current"
    elif [[ $GFX_CARD == ATI ]] || [[ $GFX_CARD == AMD ]] || [[ $GFX_CARD == ADVANCED ]]; then
        VIDEO_DRIVER="fglrx"
    elif [[ $GFX_CARD == INTEL ]]; then
        VIDEO_DRIVER="i965-va-driver"
    else
        cleanUp
        clear
        echo ""
        echo "$(tput setaf 1)$(tput bold)Installation aborted...$(tput sgr0)" 
        echo "$(tput setaf 1)Only NVIDIA, ATI/AMD or INTEL videocards are supported. Please install a compatible videocard and run the script again.$(tput sgr0)"
        echo ""
        echo "$(tput setaf 1)You have a $GFX_CARD videocard.$(tput sgr0)"
        echo ""
        exit
    fi
    
    IS_INSTALLED=$(aptInstall $VIDEO_DRIVER)

    if [ "$IS_INSTALLED" == "1"]; then
        if [ "$GFX_CARD" == "ATI" ] || [ "$GFX_CARD" == "AMD" ]; then
            configureAtiDriver

            dialog --title "Disable underscan" \
                --backtitle "$SCRIPT_TITLE" \
                --yesno "Do you want to disable underscan (removes black borders)? Do this only if you're sure you need it!" 7 $DIALOG_WIDTH

            RESPONSE=$?
            case ${RESPONSE//\"/} in
                0) 
                    disbaleAtiUnderscan
                    ;;
                1) 
                    enableAtiUnderscan
                    ;;
                255) 
                    showInfo "ATI underscan configuration skipped"
                    ;;
            esac
        fi
        
        showInfo "$GFX_CARD video drivers successfully installed and configured"
    fi
}

function installAutomaticDistUpgrade()
{
    showInfo "Enabling automatic system upgrade..."
	createDirectory "$TEMP_DIRECTORY" 1 0
	download $DOWNLOAD_URL"dist_upgrade.sh"
	IS_MOVED=$(move $TEMP_DIRECTORY"dist_upgrade.sh" "$DIST_UPGRADE_FILE" 1)
	
	if [ "$IS_MOVED" == "1" ]; then
	    IS_INSTALLED=$(aptInstall cron)
	    sudo chmod +x "$DIST_UPGRADE_FILE" > /dev/null 2>&1
	    handleFileBackup "$CRONTAB_FILE" 1
	    appendToFile "$CRONTAB_FILE" "0 */4  * * * root  $DIST_UPGRADE_FILE >> $DIST_UPGRADE_LOG_FILE"
	else
	    showError "Automatic system upgrade interval could not be enabled"
	fi
}

function removeAutorunFiles()
{
    if [ -e "$PLEX_INIT_FILE" ]; then
        showInfo "Removing existing autorun script..."
        sudo update-rc.d plexhometheater remove > /dev/null 2>&1
        sudo rm "$PLEX_INIT_FILE" > /dev/null 2>&1

        if [ -e "$PLEX_INIT_CONF_FILE" ]; then
		    sudo rm "$PLEX_INIT_CONF_FILE" > /dev/null 2>&1
	    fi
	    
	    if [ -e "$PLEX_CUSTOM_EXEC" ]; then
	        sudo rm "$PLEX_CUSTOM_EXEC" > /dev/null 2>&1
	    fi
	    
	    if [ -e "$PLEX_XSESSION_FILE" ]; then
	        sudo rm "$PLEX_XSESSION_FILE" > /dev/null 2>&1
	    fi
	    
	    showInfo "Old autorun script successfully removed"
    fi
}

function installPlexInitScript()
{
    removeAutorunFiles
    showInfo "Installing ${NAME} init.d autorun support..."
    createDirectory "$TEMP_DIRECTORY" 1 0
	download $PLEX_INIT_URL
	
	if [ -e $TEMP_DIRECTORY"plexhometheater" ]; then
	    if [ -e $PLEX_INIT_FILE ]; then
		    sudo rm $PLEX_INIT_FILE > /dev/null 2>&1
	    fi
	    
	    IS_MOVED=$(move $TEMP_DIRECTORY"plexhometheater" "$PLEX_INIT_FILE")

	    if [ "$IS_MOVED" == "1" ]; then
	        sudo chmod a+x "$PLEX_INIT_FILE" > /dev/null 2>&1
	        sudo update-rc.d plexhometheater defaults > /dev/null 2>&1
	        
	        if [ "$?" == "0" ]; then
                showInfo "${NAME} autorun succesfully configured"
            else
                showError "${NAME} autorun script could not be activated (error code: $?)"
            fi
	    else
	        showError "${NAME} autorun script could not be installed"
	    fi
	else
	    showError "Download of ${NAME} autorun script failed"
	fi
}

function installPlexUpstartScript()
{
    removeAutorunFiles
    showInfo "Installing ${NAME} upstart autorun support..."
    createDirectory "$TEMP_DIRECTORY" 1 0
	download $DOWNLOAD_URL"xbmc_upstart_script_2"

	if [ -e $TEMP_DIRECTORY"xbmc_upstart_script_2" ]; then
	    IS_MOVED=$(move $TEMP_DIRECTORY"xbmc_upstart_script_2" "$PLEX_INIT_CONF_FILE")

	    if [ "$IS_MOVED" == "1" ]; then
	        sudo ln -s "$UPSTART_JOB_FILE" "$PLEX_INIT_FILE" > /dev/null 2>&1
	    else
	        showError "${NAME} upstart configuration failed"
	    fi
	else
	    showError "Download of ${NAME} upstart configuration file failed"
	fi
}

function installNyxBoardKeymap()
{
    showInfo "Applying Pulse-Eight Motorola NYXboard advanced keymap..."
	createDirectory "$TEMP_DIRECTORY" 1 0
	download $DOWNLOAD_URL"nyxboard.tar.gz"
    createDirectory "$PLEX_KEYMAPS_DIR" 0 0

    if [ -e $PLEX_KEYMAPS_DIR"keyboard.xml" ]; then
        handleFileBackup $PLEX_KEYMAPS_DIR"keyboard.xml" 0 1
    fi

    if [ -e $TEMP_DIRECTORY"nyxboard.tar.gz" ]; then
        tar -xvzf $TEMP_DIRECTORY"nyxboard.tar.gz" -C "$PLEX_KEYMAPS_DIR" > /dev/null 2>&1
        
        if [ "$?" == "0" ]; then
	        showInfo "Pulse-Eight Motorola NYXboard advanced keymap successfully applied"
	    else
	        showError "Pulse-Eight Motorola NYXboard advanced keymap could not be applied (error code: $?)"
	    fi
    else
	    showError "Pulse-Eight Motorola NYXboard advanced keymap could not be downloaded"
    fi
}

#function installXbmcBootScreen()
#{
#    showInfo "Installing ${NAME} boot screen (please be patient)..."
#    #IS_INSTALLED=$(aptInstall v86d)
#    #IS_INSTALLED=$(aptInstall plymouth-label)
#    sudo apt-get install -y plymouth-label v86d > /dev/null
#    createDirectory "$TEMP_DIRECTORY" 1 0
#    download $DOWNLOAD_URL"plymouth-theme-xbmc-logo.deb"
    
#    if [ -e $TEMP_DIRECTORY"plymouth-theme-xbmc-logo.deb" ]; then
#        sudo dpkg -i $TEMP_DIRECTORY"plymouth-theme-xbmc-logo.deb" > /dev/null 2>&1
#        update-alternatives --install /lib/plymouth/themes/default.plymouth default.plymouth /lib/plymouth/themes/xbmc-logo/xbmc-logo.plymouth 100 > /dev/null 2>&1
#        handleFileBackup "$INITRAMFS_SPLASH_FILE" 1 1
#        createFile "$INITRAMFS_SPLASH_FILE" 1 1
#        appendToFile "$INITRAMFS_SPLASH_FILE" "FRAMEBUFFER=y"
#        showInfo "XBMC boot screen successfully installed"
#    else
#        showError "Download of XBMC boot screen package failed"
#    fi
#}

function applyScreenResolution()
{
    RESOLUTION="$1"
    
    showInfo "Applying bootscreen resolution (will take a minute or so)..."
    handleFileBackup "$GRUB_HEADER_FILE" 1 0
    sudo sed -i '/gfxmode=/ a\  set gfxpayload=keep' "$GRUB_HEADER_FILE" > /dev/null 2>&1
    GRUB_CONFIG="nomodeset usbcore.autosuspend=-1 video=uvesafb:mode_option=$RESOLUTION-24,mtrr=3,scroll=ywrap"
    
    if [[ $GFX_CARD == INTEL ]]; then
        GRUB_CONFIG="usbcore.autosuspend=-1 video=uvesafb:mode_option=$RESOLUTION-24,mtrr=3,scroll=ywrap"
    fi
    
    handleFileBackup "$GRUB_CONFIG_FILE" 1 0
    appendToFile "$GRUB_CONFIG_FILE" "GRUB_CMDLINE_LINUX=\"$GRUB_CONFIG\""
    appendToFile "$GRUB_CONFIG_FILE" "GRUB_GFXMODE=$RESOLUTION"
    
    handleFileBackup "$INITRAMFS_MODULES_FILE" 1 0
    appendToFile "$INITRAMFS_MODULES_FILE" "uvesafb mode_option=$RESOLUTION-24 mtrr=3 scroll=ywrap"
    
    sudo update-grub > /dev/null 2>&1
    sudo update-initramfs -u > /dev/null
    
    if [ "$?" == "0" ]; then
        showInfo "Bootscreen resolution successfully applied"
    else
        showError "Bootscreen resolution could not be applied"
    fi
}

function installLmSensors()
{
    showInfo "Installing temperature monitoring package (apply all defaults)..."
    aptInstall lm-sensors
    clear
    echo ""
    echo "$(tput setaf 2)$(tput bold)INSTALLATION INFO: Please confirm all questions with ENTER (applying the suggested option)."
    echo "$(tput setaf 2)The ${NAME} installation will continue automatically when finished.$(tput sgr0)"
    echo ""
    echo ""
    
    sudo sensors-detect
    
    if [ ! -e "$PLEX_ADVANCEDSETTINGS_FILE" ]; then
	    createDirectory "$TEMP_DIRECTORY" 1 0
	    download $DOWNLOAD_URL"temperature_monitoring.xml"
	    createDirectory "$PLEX_USERDATA_DIR" 0 0
	    IS_MOVED=$(move $TEMP_DIRECTORY"temperature_monitoring.xml" "$PLEX_ADVANCEDSETTINGS_FILE")

	    if [ "$IS_MOVED" == "1" ]; then
            showInfo "Temperature monitoring successfully enabled in ${NAME}"
        else
            showError "Temperature monitoring could not be enabled in ${NAME}"
        fi
    fi
    
    showInfo "Temperature monitoring successfully configured"
}

function reconfigureXServer()
{
    showInfo "Configuring X-server..."
    handleFileBackup "$XWRAPPER_FILE" 1
    createFile "$XWRAPPER_FILE" 1 1
	appendToFile "$XWRAPPER_FILE" "allowed_users=anybody"
	showInfo "X-server successfully configured"
}

function selectPlexStartupMethod()
{
    cmd=(dialog --backtitle "${NAME} autorun method"
        --radiolist "Please select the method used to start ${NAME} (default recommended):" 
        15 $DIALOG_WIDTH 3)
        
    options=(1 "init.d" on
            2 "upstart (experimental)" off)
         
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

    case ${choice//\"/} in
        1)
            installPlexInitScript
            ;;
        2)
            installPlexUpstartScript
            ;;
        *)
            selectStartupMethod
            ;;
    esac
}

function selectPlexTweaks()
{
    cmd=(dialog --title "Optional ${NAME} tweaks and additions" 
        --backtitle "$SCRIPT_TITLE" 
        --checklist "Plese select to install or apply:" 
        15 $DIALOG_WIDTH 6)
        
    options=(1 "Enable dirty region rendering (improved performance)" on
            2 "Enable temperature monitoring (confirm with ENTER)" on
            3 "Apply improved Pulse-Eight Motorola NYXboard keymap" off)
            
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

    for choice in $choices
    do
        case ${choice//\"/} in
            1)
                enableDirtyRegionRendering
                ;;
            2)
                installLmSensors
                ;;
            3)
                installNyxBoardKeymap 
                ;;
        esac
    done
}

function selectScreenResolution()
{
    cmd=(dialog --backtitle "Select bootscreen resolution (required)"
        --radiolist "Please select your screen resolution, or the one sligtly lower then it can handle if an exact match isn't availabel:" 
        15 $DIALOG_WIDTH 6)
        
    options=(1 "720 x 480 (NTSC)" off
            2 "720 x 576 (PAL)" off
            3 "1280 x 720 (HD Ready)" off
            4 "1366 x 768 (HD Ready)" on
            5 "1920 x 1080 (Full HD)" off)
         
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

    case ${choice//\"/} in
        1)
            applyScreenResolution "720x480"
            ;;
        2)
            applyScreenResolution "720x576"
            ;;
        3)
            applyScreenResolution "1280x720"
            ;;
        4)
            applyScreenResolution "1366x768"
            ;;
        5)
            applyScreenResolution "1920x1080"
            ;;
        *)
            selectScreenResolution
            ;;
    esac
}

function selectAdditionalPackages()
{
    cmd=(dialog --title "Other optional packages and features" 
        --backtitle "$SCRIPT_TITLE" 
        --checklist "Plese select to install:" 
        15 $DIALOG_WIDTH 6)
        
    options=(1 "Lirc (IR remote support)" off
            2 "Automatic upgrades (every 4 hours)" off)
            
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

    for choice in $choices
    do
        case ${choice//\"/} in
            1)
                installLirc
                ;;
            2)
                installAutomaticDistUpgrade
                ;;
        esac
    done
}

function optimizeInstallation()
{
    showInfo "Optimizing installation..."
    sudo service apparmor stop > /dev/null &2>1
    sudo service apparmor teardown > /dev/null &2>1
    sudo apt-get -y remove apparmor > /dev/null &2>1
    handleFileBackup "$SYSCTL_CONF_FILE" 1 0
    createFile "$SYSCTL_CONF_FILE" 1 0
    appendToFile "$SYSCTL_CONF_FILE" "dev.cdrom.lock=0"
    appendToFile "$SYSCTL_CONF_FILE" "vm.swappiness=10"
}

function cleanUp()
{
    showInfo "Cleaning up..."
	sudo apt-get -y autoremove > /dev/null 2>&1
	sudo apt-get -y autoclean > /dev/null 2>&1
	sudo apt-get -y clean > /dev/null 2>&1
	
	if [ -e "$TEMP_DIRECTORY" ]; then
	    sudo rm -R "$TEMP_DIRECTORY" > /dev/null 2>&1
	fi
	
	if [ -e "$HOME_DIRECTORY$THIS_FILE" ]; then
	    rm "$HOME_DIRECTORY$THIS_FILE" > /dev/null 2>&1
	fi
}

function rebootMachine()
{
    showInfo "Reboot system..."
	dialog --title "Installation complete" \
		--backtitle "$SCRIPT_TITLE" \
		--yesno "Do you want to reboot now?" 7 $DIALOG_WIDTH

	case $? in
        0)
            showInfo "Installation complete. Rebooting..."
            clear
            echo ""
            echo "Installation complete. Rebooting..."
            echo ""
            sudo reboot now > /dev/null 2>&1
	        ;;
	    1) 
	        showInfo "Installation complete. Not rebooting."
            quit
	        ;;
	    255) 
	        showInfo "Installation complete. Not rebooting."
	        quit
	        ;;
	esac
}

function quit()
{
	clear
	exit
}

control_c()
{
    cleanUp
    echo "Installation aborted..."
    quit
}

## ------- END functions -------

clear

createFile "$LOG_FILE" 0 1

echo ""
installDependencies
echo "Loading installer..."
showDialog "Welcome to the ${NAME} minimal installation script. Some parts may take a while to install depending on your internet connection speed.\n\nPlease be patient..."
trap control_c SIGINT

fixLocaleBug
fixUsbAutomount
applyPlexNiceLevelPermissions
addUserToRequiredGroups
addPlexPpa
distUpgrade
installVideoDriver
installXinit
installPlex
selectPlexStartupMethod
#installXbmcBootScreen
selectScreenResolution
reconfigureXServer
#installPowerManagement
installAudio
selectPlexTweaks
selectAdditionalPackages
allowRemoteWakeup
optimizeInstallation
cleanUp
rebootMachine

