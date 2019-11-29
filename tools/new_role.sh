#!/bin/sh

ROLESDIR=./roles
DIRS="tasks defaults handlers files"

if [ "$1" = "" ]
then
	echo "Please give name for new role e.g."
	echo "$0 my-new-role"
	exit 99
fi

if [ -d ${ROLESDIR}/$1 ]
then
	echo "Hakemisto ${ROLESDIR}/$1 on jo olemassa!"
	exit 99
else
	mkdir ${ROLESDIR}/$1
fi

for D in $DIRS
do
	mkdir ${ROLESDIR}/$1/${D}
done


