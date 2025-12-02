import sys

if len(sys.argv) != 5:
    print("Usage: python intersect_snp.py RDA.load.score.txt GK.pmap output.txt threshold")
    sys.exit(1)

rda_file = sys.argv[1] #RDA.load.score.txt RDA
pmap_file = sys.argv[2] #GK.pmap LFMM
output_file = sys.argv[3] #output
threshold = float(sys.argv[4]) #significant_threshold

# Step 1: 读取RDA输出文件
rda_snps = set()
with open(rda_file, "r") as f:
    header = f.readline()
    for line in f:
        parts = line.strip().split("\t")
        if not parts:
            continue
        snp_raw = parts[0]
        if "_" in snp_raw:
            snp = "_".join(snp_raw.split("_")[:-1])
        else:
            snp = snp_raw
        rda_snps.add(snp)

# Step 2: 读取LFMM输出文件
pmap_snps = set()
with open(pmap_file, "r") as f:
    for line in f:
        parts = line.strip().split("\t")
        if len(parts) < 4:
            continue
        snp = parts[0]
        value = float(parts[3])
        if value >= threshold:
            pmap_snps.add(snp)

# Step 3: 取共有SNP
intersect = rda_snps.intersection(pmap_snps)

# Step 4: 输出
with open(output_file, "w") as out:
    for snp in sorted(intersect):
        out.write(snp + "\n")

print(f"Done. {len(intersect)} SNPs written to {output_file}")
