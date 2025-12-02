import os,sys,re
from multiprocessing import Pool
vcf=sys.argv[1]
vcftools="/data/00/software/vcftools/vcftools-vcftools-954e607/vcftools"
admixture="/data/00/user/user153/software/dist/admixture_linux-1.3.0/admixture"
os.system('%s --gzvcf %s --plink --out Corylus'%(vcftools,vcf))
os.system('plink --noweb --file Corylus --make-bed --out Corylus')
def structure(x):
	os.system('%s --cv Corylus.bed %d | tee log%d.out'%(admixture,x,x))
po1=Pool(4)
po1.map(structure,list(range(4,8)))
po1.close()	
