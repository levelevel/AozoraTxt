#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#https://qiita.com/kichiki/items/bb65f7b57e09789a05ce

import re
import os

special_chars = '《》［］〔〕｜※'   #青空文庫の特殊文字（＃は特殊文字として扱わない）
full_mode=False #青空文庫の特殊文字を変換しない
#full_mode=True

def is_special(c):
    global special_chars
    if full_mode:
        return False
    return c in special_chars

def get_chr(m):
    if m[5]:    #Fullwitdh: U+XXXX
        return chr(int(m[5], 16))
    elif m[3]:  #U+XXXX+YYYY
        return chr(int(m[2], 16)) + chr(int(m[3], 16))
    else:       #U+XXXX
        return chr(int(m[2], 16))

with open(os.path.dirname(__file__)+'/jisx0213-2004-std.txt') as f:
    #                       1            2           3    4                         5
    ms = (re.match(r'(\d-\w{4})\s+U\+(\w{4,5})\+?(\w{4})?(\s.+\sFullwidth: U\+)?(\w{4})?', l) for l in f if l[0] != '#')
    gaiji_table = {m[1]: get_chr(m) for m in ms if m}

#外字注記sをUnicode文字に変換して返す。置き換え不可の場合はそのまま返す。
def get_gaiji(s):
    # 外字注記が入れ子になっている場合は、まず中の注記を変換する。
    s = re.sub(r'^※', '', s)
    s = re.sub(r'※［＃[^］]+］', lambda m: get_gaiji(m[0]), s)
    s = re.sub(r'^', '※', s)
    
    # ※［＃「馬＋「柳の本字、第4水準2-14-72」のつくり」、U+99F5、ページ数-行数］
    # ↑のようなケースがあるので区点コードよりもUnicodeを優先する
    # Unicode: ※［＃「皷／冬」、U+2DF78、111-下-17］
    m = re.search(r'U[+＋](\w{4,5})', s)
    if m:
        c = chr(int(m[1], 16))
        if is_special(c):
            return s
        return c
    # 区点コード:
    # ※［＃感嘆符二つ、1-8-75］
    # ※［＃「流のつくり」、第4水準2-1-18］
    m = re.search(r'[^\d]([12])-(\d{1,2})-(\d{1,2})', s)
    if m:
        key = f'{int(m[1])+2}-{int(m[2])+32:2X}{int(m[3])+32:2X}'
        c = gaiji_table.get(key, s)
        if is_special(c):
            return s
        return c
    # unknown format
    return s

# 外字注記部分をget_gaiji()で置き換える
def sub_gaiji(text):
    text = re.sub(r'※［＃(※［＃[^］]+］|[^］])*］', lambda m: get_gaiji(m[0]), text)
    #text = re.sub(r'※［＃.+?］', lambda m: get_gaiji(m[0]), text)
    #text = re.sub('／＼', '〳〵', text)
    #text = re.sub('／″＼', '〴〵', text)
    return text

def main():
    import sys
    import io
    import argparse

    sys.stdin  = io.TextIOWrapper(sys.stdin.buffer,  encoding='utf-8')
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

    parser = argparse.ArgumentParser(description='青空文庫の外字表記を文字に変換する。'
        +'プログラムと同じディレクトリにjisx0213-2004-std.txtが必要。')
    parser.add_argument('-f', '--full', action='store_true', 
        help='すべての外字を変換する。デフォルトでは青空文庫の特殊文字（'+special_chars+'）は変換しない。')
    parser.add_argument('file', nargs='?', type=argparse.FileType('r'), default=sys.stdin, 
        help='入力ファイル（UTF-8）')
    args = parser.parse_args()
    global full_mode
    full_mode = args.full

    print(sub_gaiji(args.file.read()))

if __name__ == '__main__':
    main()
