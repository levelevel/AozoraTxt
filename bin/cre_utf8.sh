
#!/bin/bash

set -u

# .../aozoratxt/bin/にある本スクリプトを起動したという前提

BIN=`dirname $0`
. $BIN/common.sh

person_from=$BIN/../person
person_to=$BIN/../person_utf8_tmp

while read txt_sjis
do
	person=`dirname "$txt_sjis"`
	person=`basename $person`
	txt_utf8=$person_to/$person/`basename "$txt_sjis" | sed 's/\(_ruby_\|_txt_\)/\0utf8_/'`
    echo $txt_utf8
	mkdir -p $person_to/$person
	$SJIS2UTF8 "$txt_sjis" | $GAIJI2UTF8 > "$txt_utf8"
	touch -r "$txt_sjis" "$txt_utf8"
done < <( find $person_from -name "*.txt" )

exit
