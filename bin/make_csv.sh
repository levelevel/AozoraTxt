
#!/bin/bash

set -u

# .../aozoratxt/bin/にある本スクリプトを起動したという前提

BIN=`dirname $0`
. $BIN/common.sh

aozora=$BIN/../../aozorabunko
person_from=$BIN/../person_utf8

echo "path,作家名" > $NAME_LIST
echo "ファイル,作品名,作家名,訳者名" > $TITLE_LIST
old_person=0
while read txt
do
    person=${txt#*person_utf8/}
    person=${person%%/*}
    if [ $old_person != $person ]; then
        old_person=$person
        p=${person#00000}
        p=${p#0000}
        p=${p#000}
        p=${p#00}
        p=${p#0}
        name=`grep 作家名： $aozora/index_pages/person$p.html | sed -e "s/作家名：//" -e "s/<[^>]*>//g" -e "s/\r//"`
        #name=${name##*\">}
        #name=${name%%<*}
        echo $person,$name >> $NAME_LIST
    fi
    title=`head -1 "$txt"`
    trans=`head -4 "$txt" | grep "訳$"`
    file=${txt##*person_utf8/}
    echo $file,$title,$name,$trans >> $TITLE_LIST
done < <( find $person_from -name "*.txt" )

exit
