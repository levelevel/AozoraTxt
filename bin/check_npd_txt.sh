#!/bin/bash

set -u

verbose=0

# .../aozoratxt/bin/にある本スクリプトを起動したという前提
# .../aozorabunkoに
# https://github.com/aozorabunko/aozorabunko.git
# がクローンされている前提

BIN=`dirname $0`
. $BIN/common.sh

LST=$TARGET_ROOT/etc/npd_txt.txt
#PERSON_PATTERN="001091"

rm -f $LST
touch $LST

#作者ごとの処理
person_cnt=0
while read person_dir
do
	let person_cnt++
	echo "$person_cnt: $person_dir"
	person_id=`basename $person_dir`
	while read txt_file
	do
		txt_id=`basename ${txt_file%%_*.txt}`
		html="$AOZORA_ROOT/cards/$person_id/card$txt_id.html"
		if [ -e $html ]; then
			grep -q "$NDP_PATTERN" $html
			if [ $? -eq 0 ]; then
				echo "$txt_file" | tee -a $LST
			fi
		else
			echo "ERROR: $html not found"
		fi
	done < <(find $person_dir -name "*.txt")
done < <(find $TARGET_ROOT/person/ -type d -name "$PERSON_PATTERN")

