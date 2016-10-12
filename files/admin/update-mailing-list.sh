#!/bin/sh

TMPDIR=$(mktemp -d)
TEMPLATE=/home/mmoa/merope-users-mailinglist.txt
TMPFILE=${TMPDIR}/maili.txt

# Let's read mail headers
if [[ -r ${TEMPLATE} ]]
then 
	cat ${TEMPLATE} > ${TMPFILE}
else 
	echo ERROR: Couldn\'t read mail-template: ${TEMPLATE}
	[[ -d ${TMPDIR}]] && rm -rf ${TMPDIR}
	exit 99
fi

# Mail addresses of all users
MAILS=`awk -F , '/@/ {print $2}'  /etc/passwd`

for M in $MAILS
do 
	echo subscribe address=$M >>  ${TMPFILE}
done

echo .| mutt -x -H ${TMPFILE} merope-users-request@listmail.tut.fi

if [[ -d ${TMPDIR} ]] 
then 
	rm -rf ${TMPDIR}
fi
