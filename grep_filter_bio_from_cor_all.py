import pandas as pd
import sys
import natsort  # 自然排序需要用到的库

# 输入文件路径
columns_file = sys.argv[1]  # 列名文件
data_file = sys.argv[2]     # 数据文件
output_file = sys.argv[3]   # 输出文件

# 读取列名文件
with open(columns_file, "r") as f:
    columns_to_extract = [line.strip() for line in f]  # 删除多余空格

# 读取数据文件
data = pd.read_csv(data_file, sep=",")  # 根据实际文件调整分隔符

# 检查列名是否匹配
columns_to_extract = ['Sample', 'Longitude', 'Latitude'] + columns_to_extract  # 保留前3列
missing_columns = [col for col in columns_to_extract if col not in data.columns]
if missing_columns:
    print("以下列名在数据文件中找不到：", missing_columns)
    sys.exit("请检查列名文件或数据文件的列名是否一致。")

# 提取需要的列
filtered_data = data[columns_to_extract]

# 排序数据（跳过第一行）
header = filtered_data.iloc[[0]]  # 提取第一行
sorted_data = filtered_data.iloc[1:].copy()  # 剩余行
sorted_data["Sample"] = sorted_data["Sample"].astype(str)  # 确保 rename2 是字符串类型

# 使用自然排序规则对 rename2 排序
sorted_data = sorted_data.sort_values(
    by="Sample", key=natsort.natsort_keygen()  # 自然排序
)

# 将第一行加回顶部
final_data = pd.concat([header, sorted_data])

# 保存结果到输出文件
final_data.to_csv(output_file, sep=",", index=False)

print(f"处理完成，结果已保存到 {output_file}")
