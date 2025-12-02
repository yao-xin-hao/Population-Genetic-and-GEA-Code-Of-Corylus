import pandas as pd
import sys
import os

#有两个用法，主要是按排序文件排序，也可以按某个文件生成一样的排序
# 确保输入的参数数量正确
if len(sys.argv) < 3:
    print("❌ 用法错误！请提供正确的输入文件。\n")
    print("✅ 第一种用法（生成 sample_order.csv）：")
    print("   python script.py file1.txt file2.txt")
    print("\n✅ 第二种用法（使用 sample_order.csv 对新文件排序）：")
    print("   python script.py sample_order.csv new_data.txt")
    sys.exit(1)

# 读取输入文件名
file1_name = sys.argv[1]
file2_name = sys.argv[2]

# **第一种情况：生成 sample_order.csv**
if not file1_name.endswith(".csv"):  # 判断是不是 sample_order.csv
    print("í ½í´¹ 生成 `sample_order.csv` 并排序 `file1` 和 `file2`...")

    # 读取文件
    file1 = pd.read_csv(file1_name, sep=",")
    file2 = pd.read_csv(file2_name, sep=",")

    # 确保第一列是 Sample
    file1.rename(columns={file1.columns[0]: "Sample"}, inplace=True)
    file2.rename(columns={file2.columns[0]: "Sample"}, inplace=True)

    # 按照 file1 的 Sample 顺序排序 file2
    file2_sorted = file2.set_index("Sample").loc[file1["Sample"]].reset_index()

    # 生成输出文件名
    file1_sorted_name = os.path.splitext(file1_name)[0] + "_sorted.txt"
    file2_sorted_name = os.path.splitext(file2_name)[0] + "_sorted.txt"
    sample_order_name = "sample_order.csv"

    # 保存排序后的文件
    file1.to_csv(file1_sorted_name, sep="\t", index=False)
    file2_sorted.to_csv(file2_sorted_name, sep="\t", index=False)

    # 保存 Sample 排åº顺序
    file1[["Sample"]].to_csv(sample_order_name, sep=",", index=False, header=True)

    print(f"✅ 排序完成，已生成:\n - {file1_sorted_name}\n - {file2_sorted_name}\n - {sample_order_name}")

# **第二种情况：使用 sample_order.csv æ序新的文件**
else:
    print(f"í ½í´¹ 使用 `{file1_name}` 排序 `{file2_name}`...")

    # 读取 sample_order.csv
    sample_order = pd.read_csv(file1_name, sep=",")
    
    # 读取新的数据文件
    new_data = pd.read_csv(file2_name, sep=",")

    # 确保第一列是 Sample
    new_data.rename(columns={new_data.columns[0]: "Sample"}, inplace=True)

    # 按照 sample_order.csv 的顺序排序新数据
    new_data_sorted = new_data.set_index("Sample").loc[sample_order["FID"]].reset_index()

    # 生成输出文件名
    new_data_sorted_name = os.path.splitext(file2_name)[0] + "_sorted.txt"

    # 保存排序后的文件
    new_data_sorted.to_csv(new_data_sorted_name, sep=",", index=False)
    print(f"✅ 排序完成，已生成 `{new_data_sorted_name}`")
