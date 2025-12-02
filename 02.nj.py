import os,sys
os.system('/data/00/software/clustalw2/clustalw-2.1-linux-x86_64-libcppstatic/clustalw2 -INFILE=ID.str.sort.min4.fasta -CONVERT -OUTFILE=merged.min4.phy -OUTPUT=PHYLIP')
os.system('/data/00/user/user153/software/phylip-3.697/exe/dnadist <<< "merged.min4.phy\nY\n" ')
os.system('mv outfile merged.min4.phylip')
os.system('/data/00/user/user153/software/phylip-3.697/exe/neighbor <<< "merged.min4.phylip\nY\n" ')
