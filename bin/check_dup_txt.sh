#!/bin/bash

set -u

verbose=0

# .../aozoratxt/bin/にある本スクリプトを起動したという前提
# .../aozorabunkoに
# https://github.com/aozorabunko/aozorabunko.git
# がクローンされている前提

BIN=`dirname $0`
. $BIN/common.sh

DUP_LST=$TARGET_ROOT/etc/duplicated_txt.txt
DUP_LST_LS=$TARGET_ROOT/etc/duplicated_txt_ls.txt
#PERSON_PATTERN="[0-9]*"

rm -f $DUP_LST $DUP_LST_LS
touch $DUP_LST

#作者ごとの処理
person_cnt=0
dup_cnt=0
while read person_dir
do
	let person_cnt++
	echo "$person_cnt: $person_dir"
	last_txt_id=""
	last_txt_file=""
	while read txt_file
	do
		txt_file=`basename "$txt_file"`
		txt_id=${txt_file%%_*.txt}
		if [ "$txt_id" == "$last_txt_id" ]; then
			let dup_cnt++
			echo "$last_txt_file	$txt_file" | tee -a $DUP_LST
			ls -l "$person_dir/$last_txt_file" \
				  "$person_dir/$txt_file" >> $DUP_LST_LS
		fi
		last_txt_id="$txt_id"
		last_txt_file="$txt_file"
	done < <(find $person_dir -name "*.txt"|sort)
done < <(find $TARGET_ROOT/person*/ -type d -name "$PERSON_PATTERN")

echo "Dup count:$dup_cnt"