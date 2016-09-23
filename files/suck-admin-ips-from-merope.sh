#!/bin/bash
dig @10.1.1.2 ilo. -tAXFR | awk '$4 ~ /^A$/  {split ($1, HN, "\."); print $5 " " $1 "  " HN[1]}' 
