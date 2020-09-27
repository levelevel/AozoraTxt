
#!/bin/bash

set -u

# .../aozoratxt/bin/にある本スクリプトを起動したという前提

BIN=`dirname $0`
. $BIN/common.sh
cd $BIN/..

MakeZip(){
	person_from="$1"
	person_zip="$2"
	if [ -e $person_zip ]; then
		DATE=`date +%Y%m%d -r $person_zip`
		person_old=`echo $person_zip | sed "s/\.zip/_$DATE.zip/"`
		mv $person_zip $person_old
	fi
	"$ZIP" $ZIP_OPT $person_zip $person_from
}

ZIP_SJIS=AozoraTxt_SJIS.zip
ZIP_UTF8=AozoraTxt_UTF8.zip
NUM_PERSON=`ls -1 person | wc -l`
NUM_FILE=`find person -name "*.txt" | wc -l`
TODAY=`date +%Y/%m/%d`

cat << EOF > Release.md
${TODAY}時点での青空文庫テキストファイル一式
（作家数：$NUM_PERSON、ファイル数：$NUM_FILE）

- $ZIP_SJIS : 青空文庫全文書SJIS版
- $ZIP_UTF8 : 青空文庫全文書UTF8版
EOF

MakeZip person      $ZIP_SJIS
MakeZip person_utf8 $ZIP_UTF8

exit
