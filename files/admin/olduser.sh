#!/bin/bash
LOGFILE=/var/log/user_accounts.log
MY_HOME=""
# keskinep:x:11006:11006:Panu Keskinen,panu.keskinen@tut.fi,61102,jaakko.akola@tut.fi:/home/keskinep:/bin/bash
#PWENT=$(getent passwd keskinep)

usage () {
        echo USAGE: $0 username 
        echo
        echo    Give existing username
        echo
        exit 99
}

no_root () {
        echo Please don\'t use sudo in front of this command!
        echo I\'ll do that myself when needed.
        exit 99
}

get_my_home () {
		MY_HOME=$(getent passwd $1|cut -d: -f6)
}

logmsg () {
	MYDATE=$(date +"%Y-%m-%d %T")
	echo "$MYDATE: $1" | sudo tee -a ${LOGFILE}
}

disable_user () {
	logmsg "Disabling old user $1 by $USER"
	MYDATE=$(date +"%Y%m%d")
	sudo mv $MY_HOME $MY_HOME.old.$MYDATE
}
	
if [ "$1" = "" ]
then
        usage
fi

if [ "$UID" = "0" ]
then
        no_root
fi

while [ "$1" != "" ]
do 
	get_my_home $1
	if [ "$MY_HOME" != "" ]
	then
		disable_user $1
	else
		echo
		echo "User home to $1 doesn't exist!"
		echo 
	fi
	shift
done
