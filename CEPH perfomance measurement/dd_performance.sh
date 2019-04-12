#!/bin/bash

dd=`which dd`
date=`which date`

#your params
path="/media/hilmi/3739-3633"
bs=1M
count=100
repetition="1"

for i in `seq 1 $repetition`; do
	rm -f "$path"/test_performance
	echo "================================================================="
	timestamp=`$date`
	echo "$timestamp"
	echo "write speed"
	$dd if=/dev/zero of="$path"/test_performance bs="$bs" count="$count" oflag=direct
	echo "-----------------------------------------------------------------"
	echo "read speed"
	$dd if="$path"/test_performance of=/dev/null bs="$bs" count="$count" iflag=direct
done
