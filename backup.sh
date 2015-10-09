#!/bin/sh
ROOT=~/.rsyncbackup
CONFIG=$ROOT/config
UTILS=$ROOT/utilities.sh
BLOCK=/tmp/backupblock

# Source usefull functions
if [ -f $UTILS ]; then
	. $UTILS
else
	exitError "ERROR: Missing file 'utilities.sh'"
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

if rsync -v -i -z --exclude-from=$EXCLUDE --rsh="ssh -i $ID_FILE -C -p $PORT" --delete -a $DIR $USER@$HOST:$EXTDIR; then
	echo "Rsync ran without problems."
	echo "$(date +%s)" > /tmp/rsync.date
	if rsync -z --rsh="ssh -i $ID_FILE -C -p $PORT" -a /tmp/rsync.date $USER@$HOST:$EXTDIR; then
		setUnixStamp $LASTRUN	
		sendNotification "$NOTIFY_TITLE" "$NOTIFY_SUCCESS"
	else
		echo "Problem occured during ssh run."
	fi
else
	echo "A problem occured during rsync run."
fi

# Cleaning up
rm $BLOCK
exit 0
