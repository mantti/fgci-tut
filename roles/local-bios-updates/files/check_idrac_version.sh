#!/bin/sh
#ipmi-oem dell get-system-info idrac-info |awk -F " : " '/Firmware Version/{print $2}'
#ipmi-oem dell get-system-info idrac-info |awk -F " : " '/Firmware Version/{split($2,AR,/ /) ;print AR[1]}'
bmc-info |awk -F": " '/Firmware Revision/{print $2}'
