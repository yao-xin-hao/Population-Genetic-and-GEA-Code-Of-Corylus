import pandas as pd
import os
import sys

data_file = sys.argv[1]  # 数据文件路径

data = pd.read_csv(data_file, sep=",")

columns_to_extract = data.columns[3:]

if not columns_to_extract.any():
    sys.exit("未找到第三列之后的列，请检查数据文件。")

for col in columns_to_extract:
    output_dir = col
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    column_data = data[[col]]

    output_file = os.path.join(output_dir, f"{col}.env")
    column_data.to_csv(output_file, index=False, header=False)
    print(f"已保存 {col} 数据到 {output_file}")

print("✅ 所有列处理完成！")
