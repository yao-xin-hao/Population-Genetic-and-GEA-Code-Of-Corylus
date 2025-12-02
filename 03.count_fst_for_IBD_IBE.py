import os
import pandas as pd
import concurrent.futures
from itertools import combinations

# 输入文件路径
adaptive_vcf = "adapt_rename.vcf.gz"  # 适应性SNP文件
neutral_vcf = "neterl_rename.vcf.gz"    # 中性SNP文件
sample_class_file = "sample_class.txt" # 样本和群体对应关系

# 输出文件路径
output_adaptive_fst = "adaptive_fst_matrix.txt"
output_neutral_fst = "neutral_fst_matrix.txt"

# 解析sample_class.txt文件
def parse_sample_class(file):
    sample_to_group = {}
    with open(file, 'r') as f:
        for line in f:
            sample, group = line.strip().split(',')
            sample_to_group[sample] = group
    return sample_to_group

# 根据群体分组样本
def group_samples_by_population(sample_to_group, vcf_samples):
    group_to_samples = {}
    for sample in vcf_samples:
        if sample in sample_to_group:
            group = sample_to_group[sample]
            if group not in group_to_samples:
                group_to_samples[group] = []
            group_to_samples[group].append(sample)
    return group_to_samples

# 提取VCF文件中的样本列表
def extract_vcf_samples(vcf_file):
    samples = []
    with os.popen(f"zgrep -m 1 '#CHROM' {vcf_file}") as f:
        header = f.read().strip()
        if header.startswith("#CHROM"):
            samples = header.split('\t')[9:]  # 从第9列开始是样本
    return samples

# 计算VCF文件中的SNP数量
def count_snps_in_vcf(vcf_file):
    snp_count = 0
    with os.popen(f"zgrep -v '^#' {vcf_file} | wc -l") as f:
        snp_count = int(f.read().strip())
    return snp_count

# 运行vcftools计算Fst
def calculate_fst(vcf_file, group1_samples, group2_samples, output_prefix, window_size):
    # 写入群体样本文件
    group1_file = f"{output_prefix}_group1.txt"
    group2_file = f"{output_prefix}_group2.txt"
    with open(group1_file, 'w') as f:
        f.write('\n'.join(group1_samples) + '\n')
    with open(group2_file, 'w') as f:
        f.write('\n'.join(group2_samples) + '\n')
    
    # 运行vcftools，指定窗口大小
    fst_file = f"{output_prefix}.windowed.weir.fst"
    os.system(f"vcftools --gzvcf {vcf_file} --weir-fst-pop {group1_file} "
              f"--weir-fst-pop {group2_file} --fst-window-size {window_size} "
              f"--out {output_prefix}")
    
    # 清理临时文件
    os.remove(group1_file)
    os.remove(group2_file)
    
    # 读取加权Fst值
    weighted_fst = None
    with open(fst_file, 'r') as f:
        for line in f:
            if not line.startswith("CHROM") and line.strip():
                fields = line.split()
                if len(fields) > 4:  # 确保字段正确
                    weighted_fst = float(fields[4])  # Fst 值在第5列
                    break
    return weighted_fst

# 并行计算Fst
def parallel_fst_calculation(vcf_file, group_to_samples, window_size):
    groups = list(group_to_samples.keys())
    results = []
    
    # 定义任务函数
    def task(group1, group2):
        group1_samples = group_to_samples[group1]
        group2_samples = group_to_samples[group2]
        output_prefix = f"fst_{group1}_vs_{group2}"
        print(f"Calculating Fst between {group1} and {group2} with window size {window_size} SNPs...")
        return (group1, group2, calculate_fst(vcf_file, group1_samples, group2_samples, output_prefix, window_size))
    
    # 使用多线程并行计算
    with concurrent.futures.ThreadPoolExecutor() as executor:
        future_to_groups = {
            executor.submit(task, group1, group2): (group1, group2)
            for group1, group2 in combinations(groups, 2)
        }
        for future in concurrent.futures.as_completed(future_to_groups):
            group1, group2 = future_to_groups[future]
            try:
                results.append(future.result())
            except Exception as e:
                print(f"Error calculating Fst for {group1} and {group2}: {e}")
    
    return results

# 生成Fst矩阵
def generate_fst_matrix(vcf_file, group_to_samples, output_file, window_size):
    groups = list(group_to_samples.keys())
    fst_matrix = pd.DataFrame(0.0, index=groups, columns=groups)  # 初始化矩阵，自己对自己的Fst为0

    # 并行计算Fst
    results = parallel_fst_calculation(vcf_file, group_to_samples, window_size)

    # 填充Fst矩阵
    for group1, group2, fst_value in results:
        fst_matrix.loc[group1, group2] = fst_value
        fst_matrix.loc[group2, group1] = fst_value
    
    # 保存到文件
    fst_matrix.to_csv(output_file, sep='\t')
    print(f"Fst matrix saved to {output_file}")

# 主函数
def main():
    # 解析样本和群体对应关系
    sample_to_group = parse_sample_class(sample_class_file)
    
    # 处理适应性SNP和中性SNP
    for vcf_file, output_file in [(adaptive_vcf, output_adaptive_fst), (neutral_vcf, output_neutral_fst)]:
        print(f"Processing {vcf_file}...")
        
        # 提取VCF文件中的样本
        vcf_samples = extract_vcf_samples(vcf_file)
        
        # 根据群体分组样本
        group_to_samples = group_samples_by_population(sample_to_group, vcf_samples)
        
        # 计算VCF文件中的SNP数量
        snp_count = count_snps_in_vcf(vcf_file)
        print(f"{vcf_file} contains {snp_count} SNPs. Using this as the window size.")
        
        # 生成Fstç©阵
        generate_fst_matrix(vcf_file, group_to_samples, output_file, snp_count)

if __name__ == "__main__":
    main()
