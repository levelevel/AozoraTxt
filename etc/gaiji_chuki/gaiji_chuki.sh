#!/bin/bash

set -u

ROOT=`dirname $0`
ORG=${ROOT}/all/gaiji_chuki_all_grep.txt
F1=${ROOT}/gaiji_chuki_sort.txt
F2=${ROOT}/gaiji_chuki_uniq.txt

sed -e '1,/^■/d' -e 's/^.*: ※［＃//' -e '/が検索されました/d' $ORG |
    egrep -v '、U\+[0-9A-F]+、'         | #Unicode
    egrep -v '第[34]水準[-0-9]+」?］$'  |
    egrep -v '、[0-9]+-[0-9]+-[0-9]+］$'     | #1-13-21
    sed -e 's/、[-0-9上中下段巻序一ニ三四五六七八九はしがきコマ右左（）目次脚注本文－」]\+］//' -e 's/[、］]$//'| #末尾のページ番号取る
    egrep -v '、U\+[0-9A-F]+$'       | #ページ番号なし救済
    egrep -v '、第[34]水準[-0-9]+$'  | #ページ番号付き救済
    sort > $F1
    uniq -c $F1 > $F2