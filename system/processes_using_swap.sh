#!/bin/bash

for i in $(ls -d /proc/[0-9]*)
do
	out=$(awk '/^Swap:/ { SWAP+=$2 } END { print SWAP }' $i/smaps 2>/dev/null)
	if [ "x$out" != "x" ] && [ "x$out" != "x0" ]
  	then
    		line=$(ps -p $(echo $i | cut -d'/' -f3) | tail -n 1 | awk '{ print $4 }')
    		echo "$line : $out kB"
  	fi
done
