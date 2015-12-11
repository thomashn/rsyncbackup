#!/bin/sh
ROOT=~/.rsyncbackup
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
	errorExit "ERROR: Missing file 'config'"
fi

# Datetimes are stored in files
if [ ! -d $STORAGE ]; then
	mkdir $STORAGE
fi

if [ ! -f $LASTRUN ]; then
	setUnixStamp $LASTRUN	
fi

# It's not nice to use all the bandwidth, or to do
# backup on a slow network
if [ $BW_LIMIT == "yes" ]; then
	if ! which iperf; then
		errorExit "ERROR: Iperf is not in path. Is it installed?"
	fi

	bw=$(uploadBenchmark $HOST)
	if [ $bw == "ERROR" ]; then
		errorExit "ERROR: Could not measure bandwidth"
	elif [ $bw -le $(echo "$BW_MIN*8000" | bc) ]; then
		# If the network is too slow, there is no need to
		# keep polling the server very often.
		setUnixStamp $LASTRUN
		errorExit "ERROR: The available network is too slow."
	fi
	tbw=$(echo "($bw*0.75)/(8*1000)" | bc)
	echo "Limiting bandwidth to $tbw kB/s"
	else
	tbw=0
fi

# Has there been enough time between backups
if [ ! $(timePassed $(cat $LASTRUN)) -ge $RUN_WAIT ]; then
	errorExit "The last backup was not long enough ago."
fi

# Only one backup at a time
if ! lockFile $BLOCK $(hours 2); then
	errorExit "Backup process is already running!"
fi

if rsync --bwlimit=$tbw -v -i -z --exclude-from=$EXCLUDE --rsh="ssh -i $ID_FILE -C -p $PORT" --delete -a $DIR $USER@$HOST:$EXTDIR; then
	echo "Rsync ran without problems."
	echo "$(date +%s)" > /tmp/rsync.date
	if rsync --bwlimit=$tbw -z --rsh="ssh -i $ID_FILE -C -p $PORT" -a /tmp/rsync.date $USER@$HOST:$EXTDIR; then
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
