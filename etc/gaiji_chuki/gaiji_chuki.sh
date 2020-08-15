#!/bin/bash

set -u

ROOT=`dirname $0`
ORG=${ROOT}/gaiji_chuki_grep.txt
F1=${ROOT}/gaiji_chuki_sort.txt
F2=${ROOT}/gaiji_chuki_uniq.txt

sed -e '1,/^◎/d' -e '/が検索されました/d' $ORG |
    grep -v '^■' |
    sed 's/^・.\+: ※［＃//' |
    sed 's/、[^、]*$//' |
    sort > $F1
uniq -c $F1 > $F2