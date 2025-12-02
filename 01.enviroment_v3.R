# 加载必要包
suppressMessages({
  library(psych)
  library(corrplot)
})

# 获取输入文件名
args <- commandArgs(TRUE)
if (length(args) == 0) {
  stop("请提供输入文件名，例如: Rscript script.R your_file.csv")
}

# 读取数据
env <- read.csv(args[1], header = TRUE)

# 自动选择数值型列（去除样本信息列）
numeric_cols <- sapply(env, is.numeric)
env_data <- env[, numeric_cols]

# 输出分析变量名
cat("用于分析的环境变量：\n")
print(colnames(env_data))

# 计ç®相关系数矩阵
M <- cor(env_data, method = "pearson")

# 输出图像
# 输出图像为圆圈图
pdf(file = "cor_environment_circle.pdf", width = 8, height = 8)
corrplot(M,
         method = "circle",                              # 使用圆圈表示相关性
         col = colorRampPalette(c("#88CBEE","white","#F16E65"))(10), # 蓝-白-红渐变色
#         type = "upper",                                 # 只显示上三角
#         addCoef.col = "black",                          # 显示数值
         tl.col = "black",                                 # 变量名标签颜色
         tl.cex = 0.7,                                   # 标签字体大小
         number.cex = 0.7,                               # 数值字体大小
#         diag = FALSE)                                   # 不显示对角线
                    )
dev.off()
# 保存相关系数矩阵为表格
M_out <- cbind(Variable = rownames(M), as.data.frame(M))
write.table(M_out, file = "cor_between_envs.tsv", sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
