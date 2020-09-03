#!/bin/bash

set -u

ROOT=`dirname $0`
FORG=${ROOT}/all/gaiji_chuki_all_grep.txt
FSORT=${ROOT}/gaiji_chuki_sort.txt
FUNIQ=${ROOT}/gaiji_chuki_uniq.txt
FERROR=${ROOT}/gaiji_chuki_error.txt

#改行コードをLFにする
if grep -q '\r' $FORG; then
    tr -d '\r' < $FORG > $FORG.tmp
    touch -r $FORG $FORG.tmp
    mv $FORG.tmp $FORG
fi

#外字注記を抜き出す
# ※［＃感嘆符二つ、1-8-75］
# ※［＃「流のつくり」、第4水準2-1-18］
# ※［＃「卓＋戈」、U+39B8、32-上-8］
# ※［＃「口／恩」、168-10］
sed -e '1,/^■/d' -e 's/^.*: ※［＃//' -e '/が検索されました/d' $FORG |
    egrep -v '、U\+[0-9A-F]+、'         | #Unicode
    egrep -v '第[34]水準[12]-[-0-9]+」?］$'  |
    egrep -v '、1-([1-9]|1[0-3])-[0-9]+］$'     | #記号の区点コード1-13-21
    sed -e 's/、[-0-9上中下段巻序一ニ三四五六七八九はしがきコマ右左（）目次脚注本文－」]\+］//' -e 's/[、］]$//'| #末尾のページ番号取る
    egrep -v '、U\+[0-9A-F]+$'           | #ページ番号なし救済
    egrep -v '、第[34]水準[-0-9]+$'      | #ページ番号付き救済
    egrep -v '、[0-9]+-[0-9]+-[0-9]+$' | #ページ番号付き救済
    sort > $FSORT
    uniq -c $FSORT > $FUNIQ

#「、区点コード、ページ番号］$」を抽出
sed -e '1,/^■/d' -e '/が検索されました/d' $FORG |
    egrep -v '、U\+[0-9A-F]+、'         | #Unicode
    egrep '、(第[34]水準[12]-[-0-9]+|1-([1-9]|1[0-3])+-[0-9]+)、[-0-9上中下段巻序一ニ三四五六七八九はしがきコマ右左（）目次脚注本文－」]+］$' \
    > $FERROR

#外字注記をFUTF8に変換
FUTF8=${ROOT}/all/gaiji_chuki_all_grep_utf8.txt
gaiji2utf8.py $FORG > $FUTF8

#FUTF8に変換されなかったもの
FUTF8NO1=${ROOT}/all/gaiji_chuki_all_grep_utf8_no1_.txt
FUTF8NO2=${ROOT}/all/gaiji_chuki_all_grep_utf8_no2_.txt  #変換できるが変換しなかったもの
grep ※ $FUTF8 | egrep -v '[12]-[0-9]+-[0-9]+' > $FUTF8NO1
grep ※ $FUTF8 | egrep    '[12]-[0-9]+-[0-9]+' > $FUTF8NO2
