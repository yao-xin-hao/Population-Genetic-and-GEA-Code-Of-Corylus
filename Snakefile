configfile: "config.yaml"

def read_fai_columns(fai_file):
    with open(fai_file,'r') as file:
        return [line.split('\t')[0] for line in file]

SAMPLES = [line.strip() for line in open(config["sample.txt"],'r')]
CHRS = read_fai_columns(config["reference.fai"])

#rule all to variationfiltration
#rule all:
#    input:
#        expand("g.vcf/{sample}.g.vcf.gz",sample = SAMPLES),
#        expand("variationfiltration/{chr}.INDEL.HDflt.vcf.gz",chr= CHRS),
#        expand("variationfiltration/{chr}.SNP.HDflt.vcf.gz", chr=CHRS)

#rule all to vcf_miss_maf
rule all:
    input:
        "miss_maf/sp.miss08.maf05.vcf.gz",
        "miss_maf/sp.miss08.maf01.vcf.gz",
        "miss_maf/sp.miss06.maf05.vcf.gz",
        "miss_maf/sp.miss06.maf01.vcf.gz", 
        expand("g.vcf/{sample}.g.vcf.gz",sample = SAMPLES),        
        expand("repeat/{chr}.INDEL.dp.double.repeat.vcf.gz",chr= CHRS)
        
rule make_gvcf:
    input:
        ref="genome/reference.fasta",
        bam="bam/{sample}.dedup.bam"
    output:
        "g.vcf/{sample}.g.vcf.gz"
    threads: 6
    log:
        "log/make_gvcf/{sample}.log"
    shell:
        "{config[software][gatk]} --java-options '-Xmx10g -Djava.io.tmpdir=tmp' HaplotypeCaller -R {input.ref} -I {input.bam} -O {output} --emit-ref-confidence GVCF --native-pair-hmm-threads 6 2> {log}"

#def to_all_gvcf(gvcf_list):
#    return ' '.join(f"-V {g} \n" for g in gvcf_list)

rule generate_vcf_list:
    input:
        gvcf=expand("g.vcf/{sample}.g.vcf.gz", sample=SAMPLES)
    output:
        "vcf_list.txt"
    shell:
        """
        > {output}
        for gvcf in {input.gvcf}; do
            echo "-V $gvcf" >> {output}
        done
        """

rule combine_gvcf:
    input:
        ref="genome/reference.fasta",
        vcf_list="vcf_list.txt"
    output:
        "combine/{chr}.g.vcf.gz"
    log:
        "log/combine_gvcf/{chr}.log.log"
    threads: 6
    shell:
        """
        {config[software][gatk]} --java-options '-Xmx10g -Djava.io.tmpdir=tmp' CombineGVCFs \
        $(less {input.vcf_list}) \
        -R {input.ref} -L {wildcards.chr} -O {output} > {log} 2>&1
        """

#        """
#        gatk_command="{config[software][gatk]} --java-options '-Xmx10g -Djava.io.tmpdir=tmp' CombineGVCFs"
#        for gvcf in {input.gvcf}; do
#            gatk_command+=" -V $gvcf"
#        done
#        gatk_command+=" -R {input.ref} -L {wildcards.chr} -O {output}"
#        echo $gatk_command > {log}
#        $gatk_command 2>> {log}
#        """
#        "{config[software][gatk]} --java-options '-Xmx10g -Djava.io.tmpdir=tmp' CombineGVCFs {to_all_gvcf(input.gvcf)} -R {input.ref} -L {wildcards.chr} -O {output} 2> {log}"

rule genotype:
    input:
        ref="genome/reference.fasta",
        gvcf="combine/{chr}.g.vcf.gz"
    output:
        "genotype/{chr}.gvcf.gz"
    log:
        "log/genotype/{chr}.log.log"
    threads: 6
    shell:
        "{config[software][gatk]} --java-options '-Xmx10g -Djava.io.tmpdir=tmp' GenotypeGVCFs -R {input.ref} -V {input.gvcf} -O {output} 2> {log}"

rule selectvariants:
    input:
        gvcf="genotype/{chr}.gvcf.gz"
    output:
        indel="selectvariants/{chr}.INDEL.vcf.gz",
        snp="selectvariants/{chr}.SNP.vcf.gz"
    threads: 6
    log:
        snplog="log/selectvariants/{chr}.SNP.log.log",
        indellog="log/selectvariants/{chr}.INDEL.log.log"
    shell:
        """
        {config[software][gatk]} --java-options '-Xmx10g -Djava.io.tmpdir=tmp' SelectVariants -V {input.gvcf} -select-type SNP -O {output.snp} 2> {log.snplog};
        {config[software][gatk]} --java-options '-Xmx10g -Djava.io.tmpdir=tmp' SelectVariants -V {input.gvcf} -select-type INDEL -O {output.indel} 2> {log.indellog}
        """

rule variationfiltration:
    input:
        indel="selectvariants/{chr}.INDEL.vcf.gz",
        snp="selectvariants/{chr}.SNP.vcf.gz"
    output:
        indel="variationfiltration/{chr}.INDEL.HDflt.vcf.gz",
        snp="variationfiltration/{chr}.SNP.HDflt.vcf.gz"
    log:
        indel="log/variationfiltration/{chr}.INDEL.HDflt.log.log",
        snp="log/variationfiltration/{chr}.SNP.HDflt.log.log"
    threads: 6
    shell:
        """
        {config[software][gatk]} --java-options '-Xmx10g -Djava.io.tmpdir=tmp' VariantFiltration -V {input.indel} -filter 'QD < 2.0' --filter-name 'QD2' -filter 'QUAL < 30.0' --filter-name 'QUAL30' -filter 'FS > 200.0' --filter-name 'FS200' -filter 'ReadPosRankSum < -20.0' --filter-name 'ReadPosRankSum-20' -O {output.indel} 2> {log.indel};
        {config[software][gatk]} --java-options '-Xmx10g -Djava.io.tmpdir=tmp' VariantFiltration -V {input.snp} -filter 'QD < 2.0' --filter-name 'QD2'  -filter 'QUAL < 30.0' --filter-name 'QUAL30' -filter 'SOR > 3.0' --filter-name 'SOR3' -filter 'FS > 60.0' --filter-name 'FS60' -filter 'MQ < 40.0' --filter-name 'MQ40' -filter 'MQRankSum < -12.5' --filter-name 'MQRankSum-12.5' -filter 'ReadPosRankSum < -8.0' --filter-name 'ReadPosRankSum-8' -filter 'HaplotypeScore < 13' --filter-name 'HaplotypeScore13' -O {output.snp} 2> {log.snp}
        """
rule other_filter_PASS:
    input:
        indel="variationfiltration/{chr}.INDEL.HDflt.vcf.gz",
        snp="variationfiltration/{chr}.SNP.HDflt.vcf.gz"
    output:
        indel="PASS/{chr}.INDEL.HDflt.py.vcf.gz",
        snp="PASS/{chr}.SNP.HDflt.py.vcf.gz"
    log:
        indel="log/pass/{chr}.indel.log",
        snp="log/pass/{chr}.snp.log"
    shell:
        """
        python3 scripts/hardfileter.py {input.indel} |pigz -p 2 -c > {output.indel} 2> {log.indel};
        python3 scripts/hardfileter.py {input.snp} |pigz -p 2 -c > {output.snp} 2> {log.snp}
        """
rule other_filter_rm_5bp:
    input:
        indel="PASS/{chr}.INDEL.HDflt.py.vcf.gz",
        snp="PASS/{chr}.SNP.HDflt.py.vcf.gz"
    output:
        "rm_5bp/{chr}.INDEL.vcf.gz"
    log:
        "log/rm_5bp/{chr}.log"
    shell:
        "python3 scripts/03.rm_snp_5bpsv.py {input.indel} {input.snp} | pigz -p 2 -c > {output} 2> {log}"

rule other_filter_depth:
    input:
        "rm_5bp/{chr}.INDEL.vcf.gz"
    output:
        "filter_depth/{chr}.INDEL.dp.vcf.gz"
    log:
        "log/depth/{chr}.log"
    shell:
        "python3 scripts/depth_GQ.py {config[depth.txt]} {input} 0 | pigz -p 2 -c > {output} 2> {log}"

rule other_filter_double:
    input:
        "filter_depth/{chr}.INDEL.dp.vcf.gz"
    output:
        "double/{chr}.INDEL.dp.double.vcf.gz"
    log:
        "log/double/{chr}.log"
    shell:
        "python3 scripts/remove_double.py {input} | pigz -p 2 -c > {output} 2> {log}"

rule other_filter_repeat:
    input:
        "double/{chr}.INDEL.dp.double.vcf.gz"
    output:
        "repeat/{chr}.INDEL.dp.double.repeat.vcf.gz"
    log:
        "log/repeat/{chr}.log"
    shell:
        "python3 scripts/out_reapeat.py {config[bed]} {input} | pigz -p 2 -c > {output} 2> {log}"

rule generate_gvcf_list:
    input:
        concat_gvcf=expand("repeat/{chr}.INDEL.dp.double.repeat.vcf.gz",chr= CHRS)
    output:
        "concat_gvcf_list.txt"
    shell:
        """
        > {output}
        for gvcf in {input.concat_gvcf}; do
            echo "$gvcf" >> {output}
        done
        """

rule concat:
    input:
        "concat_gvcf_list.txt"
    output:
        "final_vcf/sp.vcf.gz"
    log:
        "log/concat/sp.log"
    shell:
        "{config[software][bcftools]} concat -f {input} -o {output} -O z 2> {log}"

rule filter_miss_maf:
    input:
        "final_vcf/sp.vcf.gz"
    output:
        miss08="miss_maf/sp.miss08.vcf.gz",
        miss06="miss_maf/sp.miss06.vcf.gz"
    log:
        miss08="log/miss_maf/sp.miss08.log",
        miss06="log/miss_maf/sp.miss06.log"
    shell:
        """
        {config[software][vcftools]} --gzvcf {input} --max-missing 0.8  --recode --recode-INFO-all --stdout |pigz -p 2 -c > {output.miss08} 2> {log.miss08};
        {config[software][vcftools]} --gzvcf {input} --max-missing 0.6  --recode --recode-INFO-all --stdout |pigz -p 2 -c > {output.miss06} 2> {log.miss06}
        """

rule maf:
    input:
        miss08="miss_maf/sp.miss08.vcf.gz",
        miss06="miss_maf/sp.miss06.vcf.gz"
    output:
        miss08_maf05="miss_maf/sp.miss08.maf05.vcf.gz",
        miss08_maf01="miss_maf/sp.miss08.maf01.vcf.gz",
        miss06_maf05="miss_maf/sp.miss06.maf05.vcf.gz",
        miss06_maf01="miss_maf/sp.miss06.maf01.vcf.gz"
    log:
        miss08_maf05="log/miss_maf/sp.miss08.maf05.log",
        miss08_maf01="log/miss_maf/sp.miss08.maf01.log",
        miss06_maf05="log/miss_maf/sp.miss06.maf05.log",
        miss06_maf01="log/miss_maf/sp.miss06.maf01.log"
    shell:
        """
        {config[software][vcftools]} --gzvcf {input.miss08} --maf 0.05  --recode --recode-INFO-all --stdout |pigz -p 2 -c > {output.miss08_maf05} 2> {log.miss08_maf05};
        {config[software][vcftools]} --gzvcf {input.miss08} --maf 0.01  --recode --recode-INFO-all --stdout |pigz -p 2 -c > {output.miss08_maf01} 2> {log.miss08_maf01};
        {config[software][vcftools]} --gzvcf {input.miss06} --maf 0.05  --recode --recode-INFO-all --stdout |pigz -p 2 -c > {output.miss06_maf05} 2> {log.miss06_maf05};
        {config[software][vcftools]} --gzvcf {input.miss06} --maf 0.01  --recode --recode-INFO-all --stdout |pigz -p 2 -c > {output.miss06_maf01} 2> {log.miss06_maf01}
        """


