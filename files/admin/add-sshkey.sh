#!/bin/sh

MAIL_TEMPLATE=/usr/local/etc/merope-useraccount_ready.txt
LOGFILE=/var/log/user_accounts.log
MYCN=`getent passwd $USER|cut -d: -f 5|cut -d, -f 1`
MAIL=`getent passwd $USER|cut -d: -f 5|cut -d, -f 2`
TMPDIR=$(mktemp -d)

usage () {
	echo USAGE: $0 username [openssh public keyfile]
	echo
	echo 	Give existing username and ssh public key
	echo
	exit 99
}

no_root () {
        echo Please don\'t use sudo in front of this command!
        echo I\'ll do that myself when needed.
        exit 99
}

if [ "$1" = "" ]
then
	usage
fi

if [ "$UID" = "0" ] 
then
        no_root
fi

# Let's check if user account does exist

if `grep -q "^$1:" /etc/passwd` 
then
	echo Found local useraccount $1! | sudo tee -a ${LOGFILE}
else 
	echo Useraccount $1 doesn\'t exist!
	echo Use script:
	echo 
	echo /usr/local/sbin/create_user.sh $1
	echo
	echo to create it.
	exit 99
fi

echo "`date +"%Y-%m-%d %T"`: Adding ssh-key from $2 to $1 by $USER" | sudo tee -a ${LOGFILE}
if [[ `getent passwd $1` ]] 
then 
	USER=$1
	NEWHOME=`getent passwd $USER|cut -d: -f6`
	ID=`getent passwd $USER|cut -d: -f3,4`
else
	echo
	echo "`date +"%Y-%m-%d %T"`: !! User $1 didn't exist in yp, aborting !!" | sudo tee -a ${LOGFILE}
	echo
	exit 99
fi

HOME_OWNER=`getfacl ${NEWHOME} 1>/dev/null |awk '/# owner/{print $3}'`

if [ ! -r "$2" ] 
then 
	echo "Couldn't read ssh publickey from $2!  "
	read -e -p "Give users ssh-key filename:" SSH_KEY
else
	SSH_KEY="$2"
fi

if [[ `ssh-keygen -i -f $SSH_KEY >& /dev/null` ]] 
then 
	OPENSSH=False 
else
	OPENSSH=True
fi
ssh-keygen -i -f ${SSH_KEY} >& /dev/null && OPENSSH=False || OPENSSH=True

if [ "$OPENSSH" != "NO" ]
then 
	if [[ ! -d ${NEWHOME}/.ssh ]]
	then 
	 	sudo mkdir ${NEWHOME}/.ssh
	 	sudo chmod 700 ${NEWHOME}/.ssh
	 	sudo chown ${ID} ${NEWHOME}/.ssh
	fi
 
 	echo Creating ssh authorized_keys
 	if [ "$OPENSSH" = "True" ]
 	then 
		# If new user so authorized_keys doesn't exist
		if sudo /usr/bin/test ! -w ${NEWHOME}/.ssh/authorized_keys
		then
			echo Using Openssh key ${SSH_KEY}
 			sudo cp ${SSH_KEY} ${NEWHOME}/.ssh/authorized_keys
		else
			# Let's add to existing authorized_keys
			echo Adding Openssh key ${SSH_KEY}
 			cat $SSH_KEY | sudo tee -a ${NEWHOME}/.ssh/authorized_keys
		fi
			
 	else
		echo Converting SSH key ${SSH_KEY}
 		ssh-keygen -i -f ${SSH_KEY} > /tmp/apu.key
		if sudo /usr/bin/test ! -w ${NEWHOME}/.ssh/authorized_keys
		then
 			sudo cp /tmp/apu.key ${NEWHOME}/.ssh/authorized_keys
		else
			echo Adding converted ssh key /tmp/apu.key
 			cat /tmp/apu.key | sudo tee -a ${NEWHOME}/.ssh/authorized_keys
		fi
		rm /tmp/apu.key
 	fi
 
	sudo chmod 600 ${NEWHOME}/.ssh/authorized_keys
	sudo chown ${ID} ${NEWHOME}/.ssh/authorized_keys

	if [[ ! -d ${NEWHOME}/backup ]]
	then 
	 	sudo mkdir ${NEWHOME}/backup
	 	sudo chmod 700 ${NEWHOME}/backup
	 	sudo chown ${ID} ${NEWHOME}/backup
	fi

	
fi
 
# Test must be run as root
if sudo /usr/bin/test ! -r ${NEWHOME}/.bash_profile
then
	echo "`date +"%Y-%m-%d %T"`: Fixing shell-defaults from /etc/skel" | sudo tee -a ${LOGFILE}
	sudo cp /etc/skel/.* ${NEWHOME}
fi

if [[ "${HOME_OWNER}" == "root" ]]
then 
	echo "`date +"%Y-%m-%d %T"`: Correcting ${NEWHOME} owner to ${ID}" | sudo tee -a ${LOGFILE}
	sudo chown -R ${ID} ${NEWHOME}
fi

MAIL=`awk -F , '/'^${USER}:'/ {print $2}'  /etc/passwd`

#set -x 

echo Adding address ${MAIL}  to merope-users mailing list
/usr/local/sbin/add-to-mailing-list.sh ${MAIL}

echo Adding user ${USER} to slurm local user group
#sudo sacctmgr -i add user name=${USER} account=local MaxJobs=128 GrpCPUs=128
sudo sacctmgr -i add user name=${USER} account=local

echo "`date +"%Y-%m-%d %T"`: Sending notification \($MAIL_TEMPLATE\) of added ssh-key to ${MAIL}" | sudo tee -a ${LOGFILE}
sed -e "s/__CN__/$MYCN/" -e "s/__MAIL__/$MAIL/" -e "s/__UID__/$USER/" < ${MAIL_TEMPLATE} > ${TMPDIR}/mail-template-$USER.txt
echo .^M| mutt -e 'set copy=no' -x -H ${TMPDIR}/mail-template-$USER.txt ${MAIL}
rm -rf ${TMPDIR}

