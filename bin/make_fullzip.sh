
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

MakeZip person      青空文庫全文書_SJIS版.zip
MakeZip person_utf8 青空文庫全文書_UTF8版.zip

exit
