#!/bin/bash

set -u

verbose=0

# .../aozoratxt/bin/にある本スクリプトを起動したという前提
# .../aozorabunkoに
# https://github.com/aozorabunko/aozorabunko.git
# がクローンされている前提

BIN=`dirname $0`
. $BIN/common.sh

LST=$TARGET_ROOT/etc/duplicated_txt_info.txt
DEL=$TARGET_ROOT/log/tmp/deleted_txt/

# $LST内のdeletedがついたファイルを削除する（$DELフォルダに移動する）。

#https://www.aozora.gr.jp/cards/001030/card47896.html	削除済み
while read pid tid other
do
	#echo $pid $tid
	txt=`ls -1 $TARGET_ROOT/person/$pid/${tid}_*.txt 2> /dev/null`
	if [ -e "$txt" ]; then
		echo $txt
		mv $txt $DEL
	fi
	txt=`ls -1 $TARGET_ROOT/person_utf8/$pid/${tid}_*.txt 2> /dev/null`
	if [ -e "$txt" ]; then
		echo $txt
		mv $txt $DEL
	fi
done < <( grep "	deleted" $LST | sed -e 's|.*cards/||' -e 's|/card| |' -e 's/\.html//')
