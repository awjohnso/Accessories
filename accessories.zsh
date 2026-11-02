#!/bin/zsh --no-rcs
# set -x

##################################### VARIABLES ##########################################

vers="1.50"
myPID=$$
scriptName=$( /usr/bin/basename ${0} )
myTimeStamp()
{
	/bin/date | /usr/bin/awk  '{ printf "%02s %02s %02s %02s\n", $1,$2,$3,$4 }'
}
Numb_Arguments=$#
argument_1="${1}"
myHost=$( /usr/sbin/scutil --get ComputerName )
loggedInUser=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
myHome=$( /usr/bin/dscl . read Users/${loggedInUser} NFSHomeDirectory | /usr/bin/awk '{print $2}' )
myLog="${myHome}/Library/Logs/accessories.log"

##################################### FUNCTIONS ##########################################

function logging()
{
    /bin/echo "$(myTimeStamp) ${myHost} ${scriptName}[${myPID}]: ${1}" | /usr/bin/tee -a "${myLog}"
}
function START_SCRIPT()
{
	/bin/echo "" | /usr/bin/tee -a "${myLog}"
	logging "Starting ${scriptName}, Version: ${vers}."
}
function EXIT_SCRIPT()
{
	logging "Ending ${scriptName}, Version: ${vers}."
	/bin/echo "" | /usr/bin/tee -a "${myLog}"
	exit 0
}
function checkForIdle()
{
		# Check to see if a movie, Zoom, or other program is preventing sleep or screensaver action. If so wait...
		# Check PreventUserIdleDisplaySleep: 1 don't sleep, 0 ok to sleep.
	PreventUserIdleDisplaySleep=$( /usr/bin/pmset -g assertions | /usr/bin/egrep -iv pid | /usr/bin/awk '/PreventUserIdleDisplaySleep/{print $2}')
	while [[ ${PreventUserIdleDisplaySleep} -gt 0 ]]; do
		logging "Prevent User Idle Display Sleep is set to prevent sleep. Waiting..."
		sleep 15
		PreventUserIdleDisplaySleep=$( /usr/bin/pmset -g assertions | /usr/bin/egrep -iv pid | /usr/bin/awk '/PreventUserIdleDisplaySleep/{print $2}')
	done
	logging "This computer is not preventing idle."
	CURRENT_EPOCH=$( /bin/date "+%s" )
}
function myDialog()
{
	/usr/local/bin/dialog \
	--icon "https://drive.usercontent.google.com/download?id=1RVqnu_A0PTf2iuaw_qAcGgeLnqkW91Xz" \
	--bannerimage "https://drive.usercontent.google.com/download?id=1kS3AV8BtrLIsqhd2b4EHAvxq16rRlabv" \
	--title "Magic ${ACCESSORY} Battery Status" \
	--button1text "Okay" \
	--ontop --messagefont "name=Verdana,size=16" \
	--position topright \
	--width "30%" \
	--height "30%" \
	--message "Your Magic ${ACCESSORY} battery is **less** than 10% charged.<br><br>**Action:** plug-in your ${ACCESSORY:l} when you leave for the day."

}
function MagicKeyaboard()
{
	ACCESSORY="Keyboard"
	LAST_EPOCH=$( /usr/bin/defaults read "$myHome/Library/Preferences/edu.stonybrook.accessory" ${ACCESSORY} )
	NEW_EPOCH=$(( ${LAST_EPOCH} + 43200 ))
	if [ ${CURRENT_EPOCH} -gt ${NEW_EPOCH} ]; then
		myKeyboardBattery=$( /usr/sbin/ioreg -c AppleDeviceManagementHIDEventService -r -l | /usr/bin/egrep -A 20  "Magic Keyboard" | /usr/bin/egrep "BatteryPercent" | /usr/bin/awk -F ' = ' '{print $2}' )
		if [ -z ${myKeyboardBattery} ]; then
			logging "No Magic ${ACCESSORY} detected."
		else
			if [ ${myKeyboardBattery} -lt 10 ]; then
				logging "Your Magic Keyboard battery is less than 10% charged. Please consider plugging the keyboaerd in when you leave for the day."
				myDialog
				/usr/bin/defaults write "$myHome/Library/Preferences/edu.stonybrook.accessory" ${ACCESSORY} -int ${CURRENT_EPOCH}
			else	
				logging "Magic ${ACCESSORY} battery still good."
				/usr/bin/defaults write "$myHome/Library/Preferences/edu.stonybrook.accessory" ${ACCESSORY} -int 0
			fi
		fi
	fi
}
function MagicMouse()
{
	ACCESSORY="Mouse"
	LAST_EPOCH=$( /usr/bin/defaults read "$myHome/Library/Preferences/edu.stonybrook.accessory" ${ACCESSORY} )
	NEW_EPOCH=$(( ${LAST_EPOCH} + 43200 ))
	if [ ${CURRENT_EPOCH} -gt ${NEW_EPOCH} ]; then
		myMouseBattery=$( /usr/sbin/ioreg -c AppleDeviceManagementHIDEventService -r -l | /usr/bin/egrep -i -A 20  "Magic Mouse" | /usr/bin/egrep "BatteryPercent" | /usr/bin/awk -F ' = ' '{print $2}' )
		
		if [ -z ${myMouseBattery} ]; then
			logging "No Magic ${ACCESSORY} detected."
		else
			if [ ${myMouseBattery} -lt 10 ]; then
				logging "Your Magic ${ACCESSORY} battery is less than 10% charged. Please consider plugging the mouse in when you leave for the day."
				myDialog
				/usr/bin/defaults write "$myHome/Library/Preferences/edu.stonybrook.accessory" ${ACCESSORY} -int ${CURRENT_EPOCH}
			else
				logging "Magic ${ACCESSORY} battery still good."
				/usr/bin/defaults write "$myHome/Library/Preferences/edu.stonybrook.accessory" ${ACCESSORY} -int 0
			fi
		fi
	fi
}
function MY_VERSION()
{
	if [[ "$1" -eq 1 ]]; then
		case $2 in
			(-v|--version)
				/bin/echo "${vers}"
				exit 0
				;;
			(*)
				exit 0
				;;
		esac
	fi
}
###################################################################################
################################## MAIN ###########################################

MY_VERSION ${Numb_Arguments} ${argument_1}
START_SCRIPT
if [ ! -e "$myHome/Library/Preferences/edu.stonybrook.accessory.plist" ]; then
	/usr/bin/defaults write "$myHome/Library/Preferences/edu.stonybrook.accessory" Keyboard -int 0
	/usr/bin/defaults write "$myHome/Library/Preferences/edu.stonybrook.accessory" Mouse -int 0
fi

checkForIdle
MagicKeyaboard
MagicMouse
EXIT_SCRIPT
