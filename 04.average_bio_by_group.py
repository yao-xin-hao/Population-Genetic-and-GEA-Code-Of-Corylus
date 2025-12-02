import pandas as pd

# 文件路径
data_file = "all_bio_sorted.txt"  # 第一个文件（样本数据）
group_file = "sample_class.txt"  # 第二个文件（样本群体归类）
output_file = "group_bio.csv"  # 输出文件

# 读取文件
data_df = pd.read_csv(data_file)  # 样本数据文件
group_df = pd.read_csv(group_file)  # 样本群体归类文件

# 确保样本列名称一致
data_df.rename(columns={"Sample": "sample"}, inplace=True)

# 合并数据和群体信息
merged_df = pd.merge(group_df, data_df, on="sample", how="inner")

# 按群体分组并计算每列的平均值（仅计算数值列）
numeric_columns = merged_df.select_dtypes(include="number").columns
result_df = merged_df.groupby("group")[numeric_columns].mean()

# 重置索引并保å­结果
result_df.reset_index(inplace=True)
result_df.rename(columns={"group": "family"}, inplace=True)
result_df.to_csv(output_file, index=False)

print(f"计算完成，结果已保存到 {output_file}")
