import os,sys,re
with open(sys.argv[1]) as fp:
    line=fp.readline()
    for line in fp:
        line=line.strip().split(',')[6:]
        line=['-9' if i == 'NA' else i for i in line]
        print(' '.join(line))
