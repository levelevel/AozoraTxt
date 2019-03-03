#!/bin/bash

set -u

verbose=0

# .../aozoratxt/bin/にある本スクリプトを起動したという前提
# .../aozorabunkoに
# https://github.com/aozorabunko/aozorabunko.git
# がクローンされている前提

BIN=`dirname $0`
. $BIN/common.sh

CreatePersonList

rm -f $COMMIT_LIST $ZIP_LIST_NPD

echo "#Creating $COMMIT_LIST"

person_total=`cat $PERSON_LIST | wc -l`
person_count=0
zip_count=0
ndp_count=0

#作者ごとの処理
while read person_from
do
	if [ ! -e $person_from/files ]; then continue; fi
	let person_count++
	person_id=`basename $person_from`

	#作品ごとの処理
	while read zip_file
	do
		txt_id=`basename ${zip_file%%_*.zip}`
		if TxtIsNPD `dirname $zip_file`"/.." $txt_id ; then
			let ndp_count++
			echo "$zip_file" >> $ZIP_LIST_NPD
			continue
		fi

		let zip_count++
		if [ $verbose -ne 0 ]; then ls -l "$zip_file"; fi
		git_zip=${zip_file#$AOZORA_ROOT/}
		git -C $AOZORA_ROOT log --date=format:'%Y/%m/%d-%H:%M:%S' \
			--pretty=format:"$person_id-$txt_id-%cd	%h	$git_zip%n" $git_zip
	done < <(find $person_from/files/ -maxdepth 1 -name "*.zip")
done < $PERSON_LIST | grep zip > $COMMIT_LIST

commit_count=`wc -l < $COMMIT_LIST`
echo "Person Count: $person_count/$person_total"
echo "Zip Count   : $zip_count (NPD:$ndp_count)"
echo "Commit Count: $commit_count"
