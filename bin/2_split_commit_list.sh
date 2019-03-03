#!/bin/bash
# コミットリストファイル(commit_all.txt)から、
# 1番目に古いコミット commit_1.txt
# 2番目に古いコミット commit_2.txt
# ...
# n番目に古いコミット commit_n.txt
# に振り分ける。
# コミットリストファイルの中身は新→旧になっているという前提

set -u

verbose=0

BIN=`dirname $0`
. $BIN/common.sh

COMMIT_LST=$TARGET_ETC/commit_all.txt
COMMIT_NTH_LST=$TARGET_ETC/commit
rm -rf $TMP
mkdir -p $TMP

echo "#Splitting $COMMIT_LST -> ${COMMIT_NTH_LST}_%n.txt"

rm -f ${COMMIT_NTH_LST}_[0-9]*.txt

cnt=1
last_txt_id=""
ruby_flag=0

while read commit zip_file npd
do
	txt_id=`basename "${zip_file%%_*.zip}"`
	if [ "$txt_id" = "" ]; then
		continue
	fi
	if [ "$txt_id" != "$last_txt_id" ];then
		case $zip_file in
		*_ruby*) 	qruby_flag=1;;
		*_txt*)		ruby_flag=0;;
		*)			continue;;
		esac
		cnt=1
		last_txt_id=$txt_id
	else
		case $zip_file in
		*_ruby*) 	ruby_flag=1;;
		*_txt*)		if [ $ruby_flag -eq 1 ]; then
						continue
					fi;;
		*)			continue;;
		esac
		let cnt++;
	fi
	echo "$commit	$zip_file	$npd" >> ${COMMIT_NTH_LST}_$cnt.txt
done < <(sort $COMMIT_LST | cut -f2-4)

wc -l ${COMMIT_NTH_LST}_*.txt
