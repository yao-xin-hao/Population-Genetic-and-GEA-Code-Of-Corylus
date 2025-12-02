import os,sys,re,gzip
with gzip.open(sys.argv[1],'rt') as fp:
	while True:
		line=fp.readline().strip()
		if not line:
			break
		if re.search('^#',line):
			print(line)
			continue
		if line.split()[6]=='PASS':
			print(line)
