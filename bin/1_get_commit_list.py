#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import glob
import subprocess
import re
import datetime

from signal import signal, SIGPIPE, SIG_DFL
signal(SIGPIPE,SIG_DFL) 

AOZORA_ROOT     = './aozorabunko'
TARGET_ROOT     = './AozoraTxt'

PERSON_TO       = f'{TARGET_ROOT}/person'
PERSON_TO_UTF8  = f'{TARGET_ROOT}/person_utf8'
TARGET_ETC      = f'{TARGET_ROOT}/etc'
TARGET_LOG      = f'{TARGET_ROOT}/log'

UPDATE          = f'{TARGET_ROOT}/etc/update'

PERSON_PATTERN  = '[0-9]*'
PERSON_LIST     = f'{TARGET_ETC}/person_list.txt'
PERSON_LIST_NPD = f'{TARGET_ETC}/person_list_npd.txt'
PERSON_ID_NPD   = f'{TARGET_ETC}/person_id_npd.txt'
LOG             = f'{TARGET_ETC}/get_commit_list.log'
#NPD_PATTERN     = '＊著作権存続＊'
NPD_PATTERN     = b'"copyright"'

COMMIT_LIST     = f'{TARGET_ETC}/commit_all.txt'
ZIP_ERROR       = f'{TARGET_ETC}/zip_error.txt'
ZIP_NPD         = f'{TARGET_ETC}/zip_npd.txt'

def PrintUpdatedZip():
    p = subprocess.Popen(f'find {AOZORA_ROOT}/cards -name "*.zip" -newer {UPDATE}',
        shell = True, stdout = subprocess.PIPE)
    for zip in iter(p.stdout.readline,b''):
        print(zip.rstrip().decode('utf8'))

def IsNPD(html):
    with open(html.rstrip(), mode='br') as f_html:
        return NPD_PATTERN in f_html.read()

def CreatePersonIdNpd():
    # NPDなperson idをファイル(PERSON_ID_NPD)に出力し、[id:True]の辞書を返す
    print(f'#Creating {PERSON_ID_NPD}')
    npd_id = []
    for html in glob.glob(f'{AOZORA_ROOT}/index_pages/person[0-9]*.html'):
        if IsNPD(html.rstrip()):
            m = re.search(r'person(\d+)', html)
            npd_id.append(m[1].zfill(6))
    npd_id.sort()
    with open(PERSON_ID_NPD, mode='w', encoding='utf-8') as f:
        for id in npd_id:
            f.write('{}\n'.format(id))
    print(len(npd_id))
    return [(id,True) for id in npd_id]

def CreatePersonIdNpd2():
    #Pipe版。glob版より少し遅い。
    print(f'#Creating {PERSON_ID_NPD}')
    p = subprocess.Popen(f'find {AOZORA_ROOT}/index_pages/ -name "person[0-9]*.html"',
    shell = True, stdout = subprocess.PIPE)
    npd_id = []
    for html in iter(p.stdout.readline,b''):
        with open(html.rstrip(), mode='br') as f_html:
            if b'"copyright"' in f_html.read():
                #print(html.rstrip().decode("utf8"))
                m = re.search(r'person(\d+)', html.decode('utf8'))
                npd_id.append(m[1].zfill(6))
    npd_id.sort()
    with open(PERSON_ID_NPD, mode='w', encoding='utf-8') as f:
        for id in npd_id:
            f.write('{}\n'.format(id))
    print(len(npd_id))

def GetGitLog(person_id,txt_id,git_zip,f,ext=''):
    git_zip = f'cards/{person_id}/files/{git_zip}'
    txt_id = int(txt_id)
    log_cnt = 0
    ext = '\t'+ext
    p = subprocess.Popen(f'git -C {AOZORA_ROOT} log --date=format:"%Y/%m/%d-%H:%M:%S" '\
		f'--pretty=format:"{person_id}-{txt_id:06d}-%cd\t%h\t{git_zip}{ext}%n" {git_zip}',\
        shell = True, stdout = subprocess.PIPE)
    for log in iter(p.stdout.readline,b''):
        if b'0' in log:
            f.write(log.decode('utf8'))
            log_cnt += 1
    return log_cnt

def GetCommitList():
    print(f'#Creating {COMMIT_LIST}')
    st_time = datetime.datetime.today()
    zip_cnt = 0
    commit_cnt = 0
    npd_cnt = 0
    with open(COMMIT_LIST, mode='w', encoding='utf-8') as f_commit_list,\
         open(ZIP_ERROR,   mode='w', encoding='utf-8') as f_zip_error,\
         open(ZIP_NPD,     mode='w', encoding='utf-8') as f_zip_npd:
        for zip in glob.glob(f'{AOZORA_ROOT}/cards/0*/files/*.zip'):
            zip_cnt += 1
            m = re.search(r'/(\d+)/files/(\d+)', zip)
            if m:
                person_id = m[1]
                txt_id    = m[2]
                #{txt_id}_*.html, {txt_id}.html
                html = os.path.join(AOZORA_ROOT,'cards',person_id,f'card{txt_id}.html')
                if os.path.exists(html):
                    if not IsNPD(html):
                        commit_cnt += GetGitLog(person_id,txt_id,os.path.basename(zip),f_commit_list)
                    else:
                        f_zip_npd.write(zip+'\n')
                        commit_cnt += GetGitLog(person_id,txt_id,os.path.basename(zip),f_commit_list,'npd')
                        npd_cnt += 1
                else:
                    f_zip_error.write(zip+'\n')
            else:
                f_zip_error.write(zip+'\n')
            if zip_cnt%20 == 0:
                print(zip_cnt,commit_cnt,zip)
            if zip_cnt >= 100000:
                break
    with open(LOG, mode='w', encoding='utf-8') as f_log:
        f_log.write(f'Zip Count   : {zip_cnt} (NPD:{npd_cnt})\n')
        f_log.write(f'Commit Count: {commit_cnt}\n')
        ed_time = datetime.datetime.today()
        f_log.write(f'Start: {st_time}\n')
        f_log.write(f'End  : {ed_time}\n')

if __name__ == '__main__':
    #PrintUpdatedZip()
    #CreatePersonIdNpd()
    #CreatePersonList()
    GetCommitList()
    