#!/usr/bin/Rscript --no-save --no-restore
library("qvalue")

args <- commandArgs(trailingOnly = TRUE)
data <- read.table(args[1], sep = "\t", strip.white = TRUE, header = FALSE, check.names = FALSE)

# 检查数据是否正确读取，尤其是数值列
print(head(data))
print(summary(data$V2))

# 处理科学计数法数据，确保没有NA或异常值
data$V2 <- as.numeric(data$V2)
data <- na.omit(data)  # 去除含有NA的行

# 使用qvalue包计算FDR
#pvalues <- data$V2
#q <- qvalue(p = pvalues,fdr.level=0.05)
#data$V3 <- q$qvalues
data$V3 <- p.adjust(data$V2,method="BH")



# 统计不同阈值下的计数
count1 <- sum(data$V3 <= 0.1)
count2 <- sum(data$V3 <= 0.05)
count3 <- sum(data$V3 <= 0.01)
count4 <- sum(data$V3 <= 0.005)
count5 <- sum(data$V3 <= 0.001)
count6 <- sum(data$V3 <= 0.0001)
count7 <- sum(data$V3 <= 0.00001)

count <- c(nrow(data), count1, count2, count3, count4, count5, count6, count7)

cat("\n", count[1], count[2], count[3], count[4], count[5], count[6], count[7], count[8] file="1fdr.count")

# 写入处理后的数据和结果
write.table(data, sep = "\t", "bio.fdr.result", row.names = FALSE, col.names = FALSE)
