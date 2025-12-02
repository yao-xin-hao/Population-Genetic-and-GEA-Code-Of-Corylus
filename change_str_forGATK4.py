#change . to ./.
#check length
import gzip,re,sys
vcf_file=sys.argv[1]
opener=gzip.open if vcf_file.endswith('.gz') else open
with opener(vcf_file,'rt') as fp:
    for line in fp:
        line=line.strip()
        if re.search('^#',line):
            print(line)
            if re.search('^#CHROM',line):
                num=len(line.split())
            continue
        line=line.split()
        point=['.']*(len(line[8].split(':'))-1)
        if len(line) !=num:
            continue
        for i in range(9,num):
            if line[i].split(':')[0] in ['.','.|.']:
                line[i]=':'.join(['./.']+point)
        print('\t'.join(line))
