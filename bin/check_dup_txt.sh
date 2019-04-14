#!/bin/bash

set -u

verbose=0

# .../aozoratxt/bin/にある本スクリプトを起動したという前提
# .../aozorabunkoに
# https://github.com/aozorabunko/aozorabunko.git
# がクローンされている前提

BIN=`dirname $0`
. $BIN/common.sh

DUP_LST=$TARGET_ROOT/etc/duplicated_txt.txt

ID1=$TARGET_ROOT/id1.txt
ID2=$TARGET_ROOT/id2.txt

find $TARGET_ROOT/person -name "*.txt" | sed 's|.*/||' | sed 's/_.*//' |
sort | tee $ID1 | uniq > $ID2
while read id
do
	find $TARGET_ROOT/person* -name "${id}_*"
done < <( diff $ID1 $ID2 | grep "<" | sed 's/< //' ) > $DUP_LST

dup_cnt=`cat $DUP_LST | wc -l`

echo "Dup count:$dup_cnt"
if [ $dup_cnt -gt 0 ]; then echo see $DUP_LST; fi

rm -f $ID1 $ID2
