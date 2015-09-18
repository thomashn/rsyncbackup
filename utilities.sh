#!/bin/sh

errorExit()
{
	echo  "$1" 1>&2
	exit 1
}

minutes()
{
	echo $(expr $1 \* 60)
}

hours()
{
	echo $(expr $1 \* 3600)	
}


unix2ut()
{
	# The date function in osx does not follow
	# the same conventions as the one in linux.
	if [ $OS == "osx" ]; then
		echo $(/bin/date -r $1 +"%d.%m.%Y %T")
	else
		echo $(date -d @$1 +"%d.%m.%Y %T")
	fi
}

fileAge()
{
	if [ $OS == "osx" ]; then
		MODTIME=$(stat -f %m $1)
	else
		MODTIME=$(stat -c %Y $1)
	fi

	echo $(expr $(date +%s) - $MODTIME)
}

setUnixStamp() 
{
	date +%s > $1
}

timePassed() 
{
	# $1 = Old unix date
	DIFF=$(expr $(date +%s) - $1)
	if [ $DIFF -ge 0 ]; then	
		echo $DIFF
		return 0
	else
		errorExit "Negative or incorrect value!"
	fi
}

checkVariable() 
{
	if [ -z $1 ]; then
		if [ $# -eq 2 ]; then
			errorExit "The variable $2 is not set!"
		else
			errorExit "Variable not set!"
		fi
	else
		return 0
	fi
}

# Find the configuration file and source it
importConfig()
{
	if [ -f $1 ]; then
		. $1
		checkVariable "$EMAIL" "EMAIL"	
		checkVariable "$USER" "USER"	
		checkVariable "$ROOT" "ROOT"	
		checkVariable "$COMPUTER" "COMPUTER"	
		checkVariable "$RUN_WAIT" "RUN_WAIT"	
		checkVariable "$PORT" "PORT"	
		checkVariable "$HOST" "HOST"	
		checkVariable "$OS" "OS"	
		checkVariable "$ID_FILE" "ID_FILE"	
		checkVariable "$NOTIFY_TITLE" "NOTIFY_TITLE"	
		checkVariable "$NOTIFY_SUCCESS" "NOTIFY_SUCCESS"	
		
		RUN_WAIT=$(minutes $RUN_WAIT)
		
		STORAGE=$ROOT/data # Where to save information between runs
		EXCLUDE=$ROOT/exclude # Folder with exclude rules
		LASTRUN=$STORAGE/unixtime.run # Last time a successful run of rsync
	
		# The user might have multiple computers	
		# so every computer is stored in a subfolder
		EXTDIR="~/$COMPUTER"
		
		# The exlude file varies between os	
		if [ $OS == "fedora" ]; then
			EXCLUDE=$EXCLUDE/fedora
		elif [ $OS == "osx" ]; then
			EXCLUDE=$EXCLUDE/osx
		elif [ $OS == "windows" ]; then
			EXCLUDE=$EXCLUDE/windows
		else
			errorExit "Wrong os specified!"
		fi
		
		#META="USER=$USER;EMAIL=$EMAIL;COMPUTER=$COMPUTER"
		
		return 0
	else
		errorExit "Could not open file $1!"
	fi
}

lockFile()
{
	# Only one backup at a time
	if [ -f $1 ]; then
		
		# You can specify a timeout on the lock
		if [ $# -eq 2 ] && [ $(fileAge $1) -ge $2 ]; then
			if kill $(cat $1); then # Removes stuck process
				echo $$ > $1
				return 0		
			fi
		fi

		# If theres no running process, there shouldn't
		# be a lock
		if ! ps -p $(cat $1) > /dev/null; then
			echo $$ > $1
			return 0		
		fi

		return 1
	else
		echo $$ > $1
		return 0
	fi
}

sendNotification()
{
	# $1 = Title
	# $2 = Subject
	if [ $OS == "fedora" ]; then
		# Finding the correct dbus when using cron
		eval "export $(egrep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $(id -u -n) gnome-session)/environ)";
		/usr/bin/notify-send -u low -t 5000 "$1" "$2"
	elif [ $OS == "osx" ]; then
		osascript -e 'display notification "'"$2"'" with title "'"$1"'"'	
	elif [ $OS == "windows" ]; then
		echo "Forget Windows!"
	fi
}
