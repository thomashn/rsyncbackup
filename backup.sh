#!/bin/sh
ROOT=~/.hjemmebackup
CONFIG=$ROOT/config
UTILS=$ROOT/utilities.sh
BLOCK=/tmp/backupblock

# Source usefull functions
if [ -f $UTILS ]; then
	. $UTILS
else
	echo "ERROR: Missing file 'utilities.sh'"
	exit 1
fi

# Get alle the variables in the config file
if ! importConfig $CONFIG; then
	exitError "ERROR: Missing file 'config'"
fi

# Datetimes are stored in files
if [ ! -d $STORAGE ]; then
	mkdir $STORAGE
fi

if [ ! -f $LASTRUN ]; then
	setUnixStamp $LASTRUN	
fi

# Has there been enough time between backups
if [ ! $(timePassed $(cat $LASTRUN)) -ge $RUN_WAIT ]; then
	errorExit "The last backup was not long enough ago."
fi

# Only one backup at a time
if ! lockFile $BLOCK $(hours 2); then
	errorExit "Backup process is already running!"
fi

if rsync -z --exclude-from=$EXCLUDE --rsh="ssh -i $ID_FILE -C -p $PORT" --delete -a $DIR $USER@$HOST:$EXTDIR; then
	echo "Rsync ran without problems."
	echo "$META;LASTRUN=$(date +%s)" > /tmp/rsync.meta
	if rsync -z --rsh="ssh -i $ID_FILE -C -p $PORT" --delete -a /tmp/rsync.meta $USER@$HOST:$EXTDIR; then
		setUnixStamp $LASTRUN	
		sendNotification "Hjemmebackup" "Sikkerhetskopiering fullført."
	else
		echo "Problem occured during ssh run."
	fi
else
	echo "A problem occured during rsync run."
fi

# Cleaning up
rm $BLOCK
exit 0
