#!/bin/bash

set -u

verbose=1

# .../aozoratxt/bin/にある本スクリプトを起動したという前提
# .../aozorabunkoに
# https://github.com/aozorabunko/aozorabunko.git
# がクローンされている前提

BIN=`dirname $0`
. $BIN/common.sh

#対象とするcommit_?.txtの決定
NUM_FILE=$TARGET_ROOT/etc/commit_num
if [ ! -f $NUM_FILE ]; then
	echo "1" > "$NUM_FILE"
fi
COMMIT_NUM=`cat $NUM_FILE`
COMMIT_LST=$TARGET_ROOT/etc/commit_$COMMIT_NUM.txt
if [ ! -e "$COMMIT_LST" ]; then
	echo "file not found: $COMMIT_LST";
	exit 1
fi

LOG=$TARGET_ROOT/log/get_txt_from_commit_list_`date +%Y%m%d%H%M`_$COMMIT_NUM.log
GIT_LOG=$TARGET_ROOT/log/get_txt_from_commit_list_git.log
rm -f $GIT_LOG
#LOG=$TARGET_ROOT/bin/get_txt_from_commit_list.log

TMP_ZIP=./xxx.zip
PERSON_TO=$TARGET_ROOT/person

#Debug
debug_mode=0
if [ $debug_mode -eq 1 ]; then
	echo "===== DEBUG MODE ====="
	LOG=$TARGET_ROOT/debug/get_txt_from_commit_list.log
	LST=$TARGET_ROOT/debug/commit_tmp.txt
	PERSON_TO=$TARGET_ROOT/debug
fi

{
commit_total=`grep zip "$COMMIT_LST" | wc -l`

echo ""
echo "======================================================================"
start_time=`date`
echo "#Extract Aozora Bunko Text Files"
echo "#Working folder: `pwd`"
echo "#Source: $AOZORA_ROOT"
echo "#Target: $TARGET_ROOT"
echo "#Commit List: $COMMIT_LST ($commit_total)"
echo "Date: $start_time"

text_count=0
accept_count=0
reject_cnt=0
rename_count=0
empty_count=0
multi_count=0
git_failed=0
npd_count=0

rm -rf $TMP
mkdir  $TMP

echo "#Extracting"

while read commit zip_file npd
do
	if [ "$zip_file" == "" ]; then continue; fi
	let text_count++
	if [ "$npd" == "npd" ]; then continue; fi
	# zip_file: ./aozorabunko/cards/000005/files/1868_ruby_22436.zip
	txt_id=`basename ${zip_file%%_*.zip}`	#1186
#	#1_get_commit_list.shで除外済み
#	if TxtIsNPD `dirname $AOZORA_ROOT/$zip_file`"/.." $txt_id ; then
#		let npd_count++
#		echo "   NPD: $zip_file"
#		echo "$zip_file" >> $ZIP_LIST_NPD
#		continue
#	fi
	case $zip_file in
	*_ruby*) txt_type="ruby_";;
	*_txt*)  txt_type="txt_";;
	*)       txt_type="";;
	esac

	person_id=`dirname "$zip_file"`
	person_id=`dirname "$person_id"`
	person_id=`basename "$person_id"`
	person_to=$PERSON_TO/$person_id
	person_to_utf8=$PERSON_TO_UTF8/$person_id
	git_person_to=${person_to#$TARGET_ROOT/}
	git_person_to_utf8=${person_to_utf8#$TARGET_ROOT/}

	if [ ! -e $person_to ]; then
		mkdir -p $person_to
	fi
	if [ ! -d $person_to_utf8 ]; then
		mkdir $person_to_utf8
	fi
	rm -rf $TMP/*

	echo "$text_count/$commit_total: $commit	$zip_file"
	git -C $AOZORA_ROOT show "$commit:$zip_file" > $TMP_ZIP
	$UNZIP "$TMP_ZIP" > /dev/null

	#txtファイルの数をカウントする
	txt_cnt=0
	while read file
	do
		let txt_cnt++
		txt_file="$file"
	done < <(find $TMP -name "*.txt")
	case $txt_cnt in
	1)	;;
	0)	let empty_count++
		echo "   empty"
		continue;;
	*)	let multi_count++
		echo "   multi text"
		ls -l $TMP
		continue
	esac

	target_file=${txt_id}_${txt_type}`basename "$txt_file"`
	target_file_utf8=${txt_id}_${txt_type}utf8_`basename "$txt_file"`

	# SJIS file
	cur_txt_file=`ls -1 $person_to/${txt_id}_*.txt 2> /dev/null`
	cur_target_file=`basename "$cur_txt_file"`
	if [ "$cur_target_file" == "" ]; then
		echo ">> add $target_file"
	elif [ "$cur_target_file" == "$target_file" ]; then
		#同じファイル名の場合はタイムスタンプで新しいほうを優先
		if [ "$cur_txt_file" -nt "$txt_file" ]; then
			let reject_cnt++
			echo "   reject (older) $txt_file"
			ls -l "$cur_txt_file" "$txt_file" 
			continue
		fi
		echo ">> update $target_file"
		echo "update	$person_to/$target_file" >> $UPDATE_FILE
	else 
		#異なるファイル名の場合はプライオリティが高いほうを優先
		cur_priority=`CalcTxtPriority "$cur_target_file"`
		new_priority=`CalcTxtPriority "$target_file"`
		if [ $cur_priority -gt $new_priority ];then
			let reject_cnt++
			echo "   reject (low priority) $target_file($new_priority) < $cur_target_file($cur_priority)"
			continue
		fi
		git -C $TARGET_ROOT mv \
			"$git_person_to/$cur_target_file" \
			"$git_person_to/$target_file" >> $GIT_LOG 2>&1
		if [ $? -eq 0 ]; then
			let rename_count++
			echo ">> git-mv $cur_target_file $target_file"
		else
			rm "$cur_txt_file"
			let git_failed++
			echo ">> mv $cur_target_file $target_file"
		fi
	fi
	let accept_count++
	mv "$txt_file" "$person_to/$target_file"

	#UTF8 file
	cur_txt_file_utf8=`ls -1 $person_to_utf8/${txt_id}_*.txt 2> /dev/null`
	cur_target_file_utf8=`basename "$cur_txt_file_utf8"`
	if [ "$cur_target_file_utf8" == "" ]; then
		echo ">> add $target_file_utf8"
	elif [ "$cur_target_file_utf8" == "$target_file_utf8" ]; then
		#同じファイル名の場合はタイムスタンプで新しいほうを優先
		if [ "$cur_txt_file_utf8" -nt "$txt_file" ]; then
			continue
		fi
		echo ">> update $target_file_utf8"
	else 
		#異なるファイル名の場合はプライオリティが高いほうを優先
		cur_priority=`CalcTxtPriority "$cur_target_file_utf8"`
		new_priority=`CalcTxtPriority "$target_file_utf8"`
		if [ $cur_priority -gt $new_priority ];then
			echo "   reject (low priority) $target_file_utf8($new_priority) < $cur_target_file_utf8($cur_priority)"
			continue
		fi
		"$GIT" -C $TARGET_ROOT mv \
			"$git_person_to/$cur_target_file_utf8" \
			"$git_person_to/$target_file_utf8" >> $GIT_LOG 2>&1
		if [ $? -eq 0 ]; then
			let rename_count++
			echo ">> git-mv $cur_target_file_utf8 $target_file_utf8"
		else
			rm "$cur_txt_file_utf8"
			let git_failed++
			echo ">> mv $cur_target_file_utf8 $target_file_utf8"
		fi
	fi
	iconv -f CP932 -t utf8 "$person_to/$target_file" |
	$GAIJI2UTF8  > "$person_to_utf8/$target_file_utf8"
	touch -r "$person_to/$target_file" "$person_to_utf8/$target_file_utf8"
done < $COMMIT_LST

rm -r $TMP $TMP_ZIP

let COMMIT_NUM++
echo "$COMMIT_NUM" > "$NUM_FILE"

text_total=`find $TARGET_ROOT -name "[0-9]*.txt" | wc -l`
echo "Title  Total: $text_total (Accepted:$accept_count/Reject:$reject_cnt/Rename:$rename_count/Empty:$empty_count/Multi txt:$multi_count/NPD:$npd_count)"
echo "Git Failed  : $git_failed"
echo "Start: $start_time"
echo "End  : `date`"

} 2>&1 | tee $LOG

