import sys
import gzip
import urllib.request
import re
def help():
    print('use:python xx.py vcf chr_sort')
    sys.exit()
try:
    vcf = sys.argv[1]
    chr_sort=sys.argv[2]
except:
    help()
opener=gzip.open if vcf.endswith('.gz') else open
chromes=[]
with open(chr_sort) as fp:
    for line in fp:
        line=line.strip()
        if not line:
            continue
        chromes.append(line)

sort_list={}
with opener(vcf,'rt') as fp:
    for line in fp:
        line=line.strip()
        if line.startswith('#'):
            print(line)
            continue
        line1=line.split()
        sort_list.setdefault(line1[0],[]).append([int(line1[1]),line])

vcf_chrs=sorted(sort_list.keys())
if len(chromes) > len(vcf_chrs):
    more=set(chromes)-set(vcf_chrs)
    print('vcf is more')
    print(more)
    sys.exit()
elif len(chromes) < len(vcf_chrs):
    more=set(vcf_chrs)-set(chromes)
    print('chr_sort is more')
    print(more)
    sys.exit()
for chr_ in chromes:
    sort_list[chr_].sort(key=lambda x:x[0])
    for line in sort_list[chr_]:
        print(line[1])
