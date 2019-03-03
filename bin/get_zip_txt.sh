#!/bin/bash

set -u

# .../aozoratxt/bin/にある本スクリプトを起動したという前提
# .../aozorabunkoに
# https://github.com/aozorabunko/aozorabunko.git
# がクローンされている前提

BIN=`dirname $0`
. $BIN/common.sh

LST=$TARGET_ETC/zip-txt.txt
rm -f $LST

#作者ごとの処理
while read person_from
do
	if [ ! -e $person_from/files ]; then continue; fi

	#作品ごとの処理
	while read zip_file
	do
		txt=`unzip -l "$zip_file" | grep -i '.txt$' | cut -c31-`
		echo "${zip_file#$AOZORA_ROOT/}	$txt"
	done < <( find $person_from/files/ -maxdepth 1 -name "*.zip" )
done < $PERSON_LIST > $LST

