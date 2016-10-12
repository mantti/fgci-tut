#!/bin/sh

LOGFILE=/var/log/user_accounts.log
LOCALUIDRANGE="-K UID_MIN=60000 -K UID_MAX=60100"
#MAIL_TEMPLATE=/usr/local/etc/merope-useraccount-draft.txt
# Setting locale for getting proper scandinavian characters
LC_CTYPE=fi_FI.iso88591

usage () {
	echo USAGE: $0 username [openssh public keyfile]
	echo
	echo "Finds given username from universitys LDAP and creates local useraccount"
	echo "accordingly. Optionally adds given private key to users authorized_keys -file." 
	echo
	exit 99
}

no_root () {
	echo Please don\'t use sudo in front of this command!
	echo I\'ll do that myself when needed.
	exit 99
}

Ask_User_Info () {
	echo "Asking information for username $1 "
	read -e -p "Give users name (e.g. Matti Virtanen):" MYCN
	read -e -p "Give users email address (e.g. pertti.peruskayttaja@gmail.com):" MAIL
	read -e -p "Give users organization (e.g. BioMeditech):" DEP
}

if [ "$UID" = "0" ] 
then
	no_root
fi

if [ "$1" = "" ]
then
	usage
fi

if [ "$2" = "" ]
then
	# Didn\'t get ssh-key let\'s go on without it
	OPENSSH=NO
else
	OPENSSH=YES
fi

echo "`date +"%Y-%m-%d %T"`: Adding user account $1 by $USER" | sudo tee -a ${LOGFILE}

# search given uid from ldap
#LDAP=$(ldapsearch -L -x -H ldap://ldap.tut.fi -b ou=people,o=tut.fi -S uid "(uid=$1)" cn mail departmentNumber)
LDAP=$(ldapsearch -D "uid=grid_unixuser,ou=ServerUsers,o=tut.fi" -y /etc/ldap.key -H ldaps://ldap.tut.fi -S cn -b "ou=People,o=tut.fi" "(uid=$1)" cn mail departmentNumber uidNumber gidNumber)
# Parsing results
CN=`echo "${LDAP}" | awk '/^cn:/{print $2 " " $3}'`
MAIL=`echo "${LDAP}" | awk '/^mail:/{print $2}'`
UIDNUMBER=`echo "${LDAP}" | awk '/^uidNumber:/{print $2}'`
GIDNUMBER=`echo "${LDAP}" | awk '/^gidNumber:/{print $2}'`
DEP=`echo "${LDAP}" | awk '/^departmentNumber:/{print $2}'|head -n1`
#MYCN=$(echo "$CN" | base64 --decode 2>/dev/null)

# Let's check if cn is base64 encoded
echo $CN | base64 --decode >/dev/null 2>&1 && MYCN=$(echo $CN|base64 --decode) || MYCN="$CN"

# Username not found in LDAP, should we create local user?
if [ "$MYCN" = "" ]
then 
	echo "`date +"%Y-%m-%d %T"`: Couldn't find user $1 from LDAP!! Suggesting local user." | sudo tee -a ${LOGFILE}
	echo "Username $1 not found in TTY-database!"
	read -e -t 60 -p "Should we create local user instead? (y/N):" -i "N" LOCAL
	case "${LOCAL}" in
		y|Y)
			echo "`date +"%Y-%m-%d %T"`: Gonna ask userdata for $1 " | sudo tee -a ${LOGFILE}
			Ask_User_Info
			# We have tight range for local uid-numbers, so let's use that
			UIDPARAMETER=${LOCALUIDRANGE}
			;;
		*)
			exit 666
			;;
	esac
# Username name found in LDAP, lets use that
else
	# Lets find out if uid or gid is already in use
	if getent passwd $UIDNUMBER > /dev/null 
	then
		echo "`date +"%Y-%m-%d %T"`: Found ID-conflict $UIDNUMBER=`getent passwd $UIDNUMBER|cut -d: -f1` <> $1 " | sudo tee -a ${LOGFILE}
		echo "UID $UIDNUMBER does already exists for user `getent passwd $UIDNUMBER|cut -d: -f1`!!"
		exit 666
	else
		UIDPARAMETER="-u $UIDNUMBER"
	fi

	if getent group $GIDNUMBER > /dev/null 
	then
		echo "`date +"%Y-%m-%d %T"`: Found GID-conflict $GIDNUMBER=`getent group $GIDNUMBER|cut -d: -f1` <> $1 " | sudo tee -a ${LOGFILE}
		echo "GID $GIDNUMBER does already exists for group `getent group $GIDNUMBER|cut -d: -f1`"
		exit 666
	else
		UIDPARAMETER="$UIDPARAMETER  -g $GIDNUMBER"
	fi

	echo "Found user $1 ($UIDNUMBER:$GIDNUMBER): ${MYCN}\<${MAIL}\> from department ${DEP}"
	read -e -t 60 -p "Is that OK (Y/n):" -i "Y" OK

	if [ "$OK" != "Y" ] 
	then
		echo "Aborted!!"
		exit 666
	fi
fi

# Let's print data we are going to use for debug
echo "CN=${CN}"
echo "UID=${UIDNUMBER}"
echo "GID=${GIDNUMBER}"
echo "MAIL=${MAIL}"
echo "DEP=${DEP}"
echo "MYCN=${MYCN}"
echo "Using CN: ${MYCN}"

TMPDIR=$(mktemp -d)

case "$DEP" in
	812*)
		MYHOME=/sgn/$1
		MYGROUPS="-G sgn"
		;;
	611*)
		MYHOME=/fys/$1
		;;
	*)	
		MYHOME=/home/$1
		;;
esac

echo "`date +"%Y-%m-%d %T"`: Gonna create usergroup $1:$GIDNUMBER" | sudo tee -a ${LOGFILE}

sudo groupadd -g $GIDNUMBER $1

echo "`date +"%Y-%m-%d %T"`: Gonna create user $1:$UIDNUMBER:$GIDNUMBER [$MYCN $DEP] with home directory $MYHOME" | sudo tee -a ${LOGFILE}

sudo useradd -c "$MYCN,$MAIL,$DEP" ${UIDPARAMETER} -d $MYHOME -m $MYGROUPS $1

sudo make -C /var/yp

sudo service ypserv restart

sudo chage -d `date --date "+1 year" '+%Y-%m-%d '` -M 365 -W 14 $1

if [ "$UIDNUMBER" = "" ] 
then 
	ID=`getent passwd $1|cut -d: -f3,4`
else
	ID="${UIDNUMBER}:${GIDNUMBER}"
fi

sudo chown -R $ID ${MYHOME}

# If we already have sshkey, so let's add it also
if [ "$OPENSSH" != "NO" ]
then 
	/usr/local/sbin/add-sshkey.sh $1 $2
# otherwise let's send instructions to key generation
else
	/usr/local/sbin/user_account_created.sh $1
fi

