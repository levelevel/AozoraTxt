#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import os

with open(os.path.dirname(__file__)+'/jisx0213-2004-std.txt') as f:
    for line in f:
        #                1        2      3            4           5     6                        7
        m = re.match(r'([34])-(\w{2})(\w{2})\s+U\+(\w{4,5})\+?(\w{4})?(\s.+\sFullwidth: U\+)?(\w{4})?', line)
        if m:
            men = int(m[1])-2
            ku  = int(m[2],16)-32
            ten = int(m[3],16)-32
            if m[7]:
                c = chr(int(m[7],16))
            elif m[5]:
                c = chr(int(m[4],16)) + chr(int(m[5],16))
            else:
                c = chr(int(m[4],16))
            print(f'※［＃{men}-{ku}-{ten}］\t{c}\t{line.rstrip()}')
            pass
        else:
            print(line.rstrip())
            pass
