
#!/bin/bash

set -u

# .../aozoratxt/bin/にある本スクリプトを起動したという前提

BIN=`dirname $0`
. $BIN/common.sh

aozora=$BIN/../../aozorabunko
person_from=$BIN/../person_utf8

echo "作家ID,作家名" > $NAME_LIST
echo "ファイル名,作品名,作家名,訳者名" > $TITLE_LIST
old_person=0
while read txt
do
    #作者名は図書カードの作家データから取得する。姓名が分かち書きされているので本文から取得するよりは有利。
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
    #本文冒頭は以下の4パターンがある。
    #1:タイトル
    #2:作者
    #
    #1:タイトル
    #2:サブタイトル
    #3:作者
    #
    #1:タイトル
    #2:作者
    #3:翻訳者
    #
    #1:タイトル
    #2:サブタイトル
    #3:作者
    #4:翻訳者
    mapfile -t array < <(head -5 "$txt" | sed -n 1,/^$/p)
    #echo ${array[@]}
    title=${array[0]}
    trans=""
    case ${#array[@]} in
    3)  author=${array[1]} ;;
    4)  case ${array[2]} in
        *訳) author=${array[1]}; trans=${array[2]} ;;
        *)   title="$title ${array[1]}"; author=${array[2]} ;;
        esac ;;
    5)  title="$title ${array[1]}"; author=${array[2]}; trans=${array[3]} ;;
    esac
    file=${txt##*person_utf8/}
    echo $file,$title,$name,$trans >> $TITLE_LIST
done < <( find $person_from -name "*.txt" )

exit
