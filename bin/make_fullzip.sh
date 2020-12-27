
#!/bin/bash

set -u

# .../aozoratxt/bin/にある本スクリプトを起動したという前提

BIN=`dirname $0`
. $BIN/common.sh

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

NUM_PERSON=`ls -1 $PERSON_TO | wc -l`
NUM_FILE=`find $PERSON_TO -name "*.txt" | wc -l`
TODAY=`date +%Y/%m/%d`

cat << EOF > $RELEASE_MD
${TODAY}時点での青空文庫テキストファイル一式
（作家数：$NUM_PERSON、ファイル数：$NUM_FILE）

- `basename $ZIP_SJIS` : 青空文庫全文書SJIS版
- `basename $ZIP_UTF8` : 青空文庫全文書UTF8版
EOF

echo "# 作家リスト、作品リスト作成中"
make_csv.sh
cp $NAME_LIST $TITLE_LIST $PERSON_TO_UTF8
$UTF82SJIS $NAME_LIST  > $PERSON_TO/${NAME_LIST##*/}
$UTF82SJIS $TITLE_LIST | sed "s/_utf8//" > $PERSON_TO/${TITLE_LIST##*/}
unix2dos $PERSON_TO/*.csv 2> /dev/null

echo "# zipファイル作成中"
MakeZip $PERSON_TO      $ZIP_SJIS
MakeZip $PERSON_TO_UTF8 $ZIP_UTF8

rm -f $PERSON_TO/*.csv
rm -f $PERSON_TO_UTF8/*.csv

exit
