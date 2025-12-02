import re
import sys
try:
    result = sys.argv[1]
except IndexError:
    print('use:python xx.py pca.n.result ')
    sys.exit()
num = ''
fp_r = open(result)
fp_w = open('%s.ggplot2_data'%(result),'w')
fp_w.write('id\tpercent\tk\n')

while True:
    line = fp_r.readline()
    if not line:
        break
    line = line.strip().split()
    while not num:
        num=len(line)-1
    for i in range(num):
        str_w = '%s\t%s\tk%d\n'%(line[0],line[i+1],i)
        fp_w.write(str_w)
fp_r.close()
fp_w.close()
