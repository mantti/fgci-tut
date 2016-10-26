#!/bin/sh
LOGFILE=/var/log/user_accounts.log
MAIL_TEMPLATE=/usr/local/etc/tcsc-useraccount-draft.txt

usage () {
	echo USAGE: $0 username 
	echo
	echo "Sends notification email when user account is created."
	echo "Mailtemplate used is ${MAIL_TEMPLATE}"
	echo
	exit 99

}

if [ "$1" = "" ]
then
	usage
fi

TMPDIR=$(mktemp -d)

# Will find users mailaddress from /etc/passwd
MAIL=`awk -F ":|," '/^'$1':/{print $6}' /etc/passwd`
MYCN=`awk -F ":|," '/^'$1':/{print $5}' /etc/passwd`

if [ "$MAIL" = "" ]
then
	echo ERROR: Couldn\'t find user $1\'s mailaddress from /etc/passwd
	echo Exiting
	echo
	exit 99
fi

# Let's send notification mail to user
sed -e "s/__CN__/$MYCN/" -e "s/__MAIL__/$MAIL/" -e "s/__UID__/$1/" < ${MAIL_TEMPLATE} > ${TMPDIR}/mail-template-$1.txt
#echo .| mutt -x -e 'set record=""' -H ${TMPDIR}/mail-template-$1.txt ${MAIL}
#env MAILRC=/dev/null mailx -a ${TMPDIR}/mail-template-${1}.txt -n -s "Your account (${1}) to merope-cluster ..." -r "TCSC <tcsc@tut.fi>" ${MAIL}
env MAILRC=/dev/null mailx -n -s "Your account (${1}) to narvi-cluster ..." -t -r "TCSC <tcsc@tut.fi>" ${MAIL} < ${TMPDIR}/mail-template-${1}.txt

#echo Core dumped to ${TMPDIR}/mail-template-$1.txt
rm -rf ${TMPDIR}
