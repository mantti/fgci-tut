#!/bin/sh

MAIL_TEMPLATE=/usr/local/etc/tcsc-useraccount_ready.txt
LOGFILE=/var/log/user_accounts.log
MYCN=`getent passwd $1|cut -d: -f 5|cut -d, -f 1`
MAIL=`getent passwd $1|cut -d: -f 5|cut -d, -f 2`
# This is for mail sender username ;-)
ADMIN=`grep $USER /etc/passwd|cut -d: -f5|cut -d, -f1`
DEP=`getent passwd simona |cut -d: -f5|cut -d, -f3`
TMPDIR=$(mktemp -d)
SLURM_ACCOUNTS=(TCSC FYS SGN BMT Students)

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
	MYUSER=$1
	NEWHOME=`getent passwd $MYUSER|cut -d: -f6`
	ID=`getent passwd $MYUSER|cut -d: -f3,4`
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

#MAIL=`awk -F , '/'^${MYUSER}:'/ {print $2}'  /etc/passwd`

#set -x 

#echo Adding address ${MAIL}  to merope-users mailing list
#/usr/local/sbin/add-to-mailing-list.sh ${MAIL}

# Let's select proper slurm-account
case "$DEP" in
	812*)
		MY_SLURM_ACCOUNT="SGN"
		;;
	611*)
		MY_SLURM_ACCOUNT="FYS"
#		MYHOME=/fys/$1
		;;
	511*)
		MY_SLURM_ACCOUNT="BMT"
		;;
	*)	
#		MYHOME=/home/$1
		MY_SLURM_ACCOUNT="TCSC"
		;;
esac

echo "============================================="
echo Defaulting to $MY_SLURM_ACCOUNT -slurm account. 
echo "If you accept the default, please press enter in 10 seconds:"
echo "============================================="

read -e -t 10 -p ":" ACCOUNT_OK
# The exit status is greater than 128 if this timeouts
if [ "$?" -ge "128" ]
then
    echo "Please select the slurm account for user ${MYUSER}"
    select MYACCOUNT in "${SLURM_ACCOUNTS[@]}"
    do  
        MY_SLURM_ACCOUNT=$MYACCOUNT
        echo Selected $MY_SLURM_ACCOUNT from $SLURM_ACCOUNTS | sudo tee -a ${LOG_FILE}
        break
    done
else
    echo Accepted default slurm account $MY_SLURM_ACCOUNT | sudo tee -a ${LOG_FILE}
fi

echo Adding user ${MYUSER} to slurm user group $MY_SLURM_ACCOUNT | sudo tee -a ${LOG_FILE}
#sudo sacctmgr -i add user name=${USER} account=local MaxJobs=128 GrpCPUs=128
sudo sacctmgr -i add user name=${MYUSER} account=$MY_SLURM_ACCOUNT

echo "`date +"%Y-%m-%d %T"`: Sending notification \($MAIL_TEMPLATE\) of added ssh-key to ${MAIL}" | sudo tee -a ${LOGFILE}
sed -e "s/__CN__/$MYCN/" -e "s/__MAIL__/$MAIL/" -e "s/__UID__/$MYUSER/" -e "s/__ADMIN__/$ADMIN/" ${MAIL_TEMPLATE} ~$USER/.signature > ${TMPDIR}/mail-template-$MYUSER.txt
#echo .^M| mutt -e 'set copy=no' -x -H ${TMPDIR}/mail-template-$MYUSER.txt ${MAIL}
env MAILRC=/dev/null mailx -n -s "Your account (${1}) to narvi-cluster ..." -t -r "TCSC <tcsc@tut.fi>" ${MAIL} < ${TMPDIR}/mail-template-$MYUSER.txt
#rm -rf ${TMPDIR}

