#!/bin/bash

if [ -z $1 ]; then

	echo "Run in form $0 <blast.outfmt6> <space delimited granularity values>\n\n "
	exit
else
	args=("$@")
	unset args[0]

	cut -f 1,2,11 $1 > seq.abc
	mcxload -abc seq.abc --stream-mirror --stream-neg-log10 -stream-tf 'ceil(160)' -o seq.mci -write-tab seq.tab

	for i in ${args[*]}; do
		mcl seq.mci -I $i -use-tab seq.tab &
	done

wait


fi
