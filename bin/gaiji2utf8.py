#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#https://qiita.com/kichiki/items/bb65f7b57e09789a05ce

import re
import os

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

def is_special(c):
    return c in '《》［］〔〕｜※'

def get_gaiji(s):
    # ※［＃感嘆符二つ、1-8-75］
    m = re.search(r'[^\d]([12])-(\d{1,2})-(\d{1,2})', s)
    if m:
        key = f'{int(m[1])+2}-{int(m[2])+32:2X}{int(m[3])+32:2X}'
        c = gaiji_table.get(key, s)
        if is_special(c):
            return s
        return c
    # ※［＃「皷／冬」、U+2DF78、111-下-17］
    m = re.search(r'U\+(\w{4,5})', s)
    if m:
        c = chr(int(m[1], 16))
        if is_special(c):
            return s
        return c
    # unknown format
    return s

def sub_gaiji(text):
    text = re.sub(r'※［＃.+?］', lambda m: get_gaiji(m[0]), text)
    #text = re.sub('／＼', '〳〵', text)
    #text = re.sub('／″＼', '〴〵', text)
    return text

def main():
    import sys
    import io
    sys.stdin  = io.TextIOWrapper(sys.stdin.buffer, encoding='utf-8')
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    if len(sys.argv) <= 1:
        print(sub_gaiji(sys.stdin.read()))
    else:
        with open(sys.argv[1], mode='r', encoding='utf-8') as f:
            print(sub_gaiji(f.read()))

if __name__ == '__main__':
    main()
