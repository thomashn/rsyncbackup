#rsyncbackup

This project uses rsync as a backup tool, with special focus on laptops. As they are constantly on the move, laptops can not simply run a backup at a specified time. Internet or local network might not always be available at 3 o'clock every day. 

The script available here is meant to deal with this issue. It's not very complicated and doesn't require any extra software if you are on a linux or OSX machine (Needs cygwin install on Windows). All three major operating systems are supported.

Running the script at very short intervals (I run it every minute) it is possible to poll the network for a connection to whatever type of server you are backing up to. The script has a simple function that checks how long it's been since the last backup and only runs the rsync command when this time has been exceded. It also has a custom semaphore (lockfile) function that makes sure that only one backup runs at any given time.

Both linux and OSX have notification centers and this script uses these by sending a confirmation when a complete backup has been successful. I tried to make a ballon type notification in Windows, but it doesn't quite work. Maybe the notification center in Windows 10 will allow this.

There are of course some risks with running a backup quite often and without the user knowing when it is actually running. Certain programs have large binary files that should not be accessed when a backup is running. This is not so common on linux and OSX, but Windows has several popular programs that do this (Outlook, SQL, etc). 
