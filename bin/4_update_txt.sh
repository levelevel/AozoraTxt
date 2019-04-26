#!/bin/bash

set -u

full_update=0
verbose=1

# .../aozoratxt/bin/にある本スクリプトを起動したという前提
# .../aozorabunkoに
# https://github.com/aozorabunko/aozorabunko.git
# がクローンされている前提

BIN=`dirname $0`
. $BIN/common.sh

LOG=$TARGET_ROOT/log/update_txt_`date +%Y%m`.log
TARGET_LOGTMP=$TARGET_LOG/tmp
mkdir -p $TARGET_LOGTMP
LAST_LOG=$TARGET_LOGTMP/update_txt_last.log
GIT_MV_LOG=$TARGET_LOGTMP/update_txt_git-mv.log
GIT_PULL_LOG=$TARGET_LOGTMP/update_txt_git-pull.log
UNZIP_LOG=$TARGET_LOGTMP/update_txt_unzip.log
#touch -t 201901261430 $UPDATE

#Debug
debug_mode=0
if [ $debug_mode -eq 1 ]; then
	echo "===== DEBUG MODE ====="
	PERSON_PATTERN="000040"
	PERSON_LIST=$TARGET_ROOT/tmp/person_list.txt
	PERSON_LIST_NPD=$TARGET_ROOT/tmp/person_list_npd.txt
	PERSON_ID_NPD=$TARGET_ROOT/tmp/person_id_npd.txt
	UPDATE=$TARGET_ROOT/tmp/update
	touch -t 198001010000 $UPDATE
	LOG=$TARGET_ROOT/tmp/get_txt.log
	PERSON_TO=$TARGET_ROOT/tmp
	TMP=$TARGET_ROOT/tmp/tmp
fi

{
echo ""
echo "======================================================================"
start_time=`date`
echo "#Extract Aozora Bunko Text Files"
echo "#Working folder: `pwd`"
echo "#Source: $AOZORA_ROOT"
echo "#Target: $TARGET_ROOT"
echo "#Date: $start_time"

echo "#Git pull"
if [ ! -e "$GIT" ]; then GIT="git"; fi
"$GIT" -C $AOZORA_ROOT pull 2>&1 |
	grep -v "Checking out" |
	tee -a $GIT_PULL_LOG |
	egrep -v -e "^ (index_pages/|create mode|cgi/npc.idx|index.html)" -e "/fig"

echo "Date: `date`"
echo "#Updating"
if [ ! -e $UPDATE ]; then
	touch -t 198001010000 $UPDATE
fi
ls -l $UPDATE

text_count=0
accept_count=0
reject_cnt=0
update_count=0
rename_count=0
empty_count=0
multi_count=0
git_failed=0
npd_count=0

TMP_ZIP_LST=$TARGET_ETC/zip_list.txt
find $AOZORA_ROOT/cards -maxdepth 3 -name "*.zip" -newer $UPDATE > $TMP_ZIP_LST
#    $AOZORA_ROOT/cards/0000001/files/*.zip
zip_total=`grep zip "$TMP_ZIP_LST" | wc -l`

rm -rf $TMP
mkdir  $TMP

while read zip_file
do
	if [ "$zip_file" == "" ]; then continue; fi
	let text_count++
	# zip_file: ./aozorabunko/cards/000005/files/1868_ruby_22436.zip
	txt_id=`basename ${zip_file%%_*.zip}`	#1186
	# NPDなファイルは除外
	if TxtIsNPD `dirname $zip_file`"/.." $txt_id ; then
		let npd_count++
		echo "   NPD: $zip_file"
		echo "$zip_file" >> $ZIP_LIST_NPD
		continue
	fi
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

	ls -l "$zip_file" | tee -a $UNZIP_LOG
	echo "$text_count/$zip_total: $zip_file"
	"$UNZIP" $UNZIP_OPT "$zip_file" >> $UNZIP_LOG

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
		ls -l $TMP
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
		let update_count++
		echo ">> update $target_file"
		echo "update	$person_to/$target_file	`date +%Y/%m/%d`" >> $UPDATE_FILE
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
			"$git_person_to/$target_file" >> $GIT_MV_LOG 2>&1
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
			"$git_person_to_utf8/$cur_target_file_utf8" \
			"$git_person_to_utf8/$target_file_utf8" >> $GIT_MV_LOG 2>&1
		if [ $? -eq 0 ]; then
			let rename_count++
			echo ">> git-mv $cur_target_file_utf8 $target_file_utf8"
		else
			rm "$cur_txt_file_utf8"
			let git_failed++
			echo ">> mv $cur_target_file_utf8 $target_file_utf8"
		fi
	fi
	$SJIS2UTF8 "$person_to/$target_file" |
	$GAIJI2UTF8 > "$person_to_utf8/$target_file_utf8"
	touch -r "$person_to/$target_file" "$person_to_utf8/$target_file_utf8"
	#タイトル、著者を表示する
	echo -n ">> "
	while read line
	do
		if [ "$line" == "" ]; then break; fi
		echo -n "$line、"
	done < "$person_to_utf8/$target_file_utf8"
	echo
done < $TMP_ZIP_LST

rm -r $TMP
rm -f $TMP_ZIP_LST

#不正なファイル名をリストアップする
echo "#Creating $FILENAME_ILLEGAL"
GetFilenameIllegal

if [ $ZIP_LIST_NPD -nt $UPDATE ]; then
	sort -u $ZIP_LIST_NPD > $ZIP_LIST_NPD.tmp
	mv $ZIP_LIST_NPD.tmp $ZIP_LIST_NPD
fi

mv $UPDATE $UPDATE.org
touch $UPDATE

text_total=`find $PERSON_TO $PERSON_TO_UTF8 -name "*.txt" | wc -l`
echo "Title Total : $text_total (Accept:$accept_count/Reject:$reject_cnt/Update:$update_count/Rename:$rename_count/Empty:$empty_count/Multi txt:$multi_count/NPD:$npd_count)"
echo "Git Failed  : $git_failed"
echo "Start: $start_time"
echo "End  : `date`"

} 2>&1 | tee $LAST_LOG | tee -a $LOG
