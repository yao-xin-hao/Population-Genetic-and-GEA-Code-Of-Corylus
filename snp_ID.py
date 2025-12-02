import gzip,sys,re
with gzip.open(sys.argv[1],'rt') as fp:
    for line in fp:
        line=line.strip()
        if re.search('^#',line):
            print(line)
            continue
        line=line.split()
        line[2]=line[0]+"_"+line[1]
        print('\t'.join(line))
