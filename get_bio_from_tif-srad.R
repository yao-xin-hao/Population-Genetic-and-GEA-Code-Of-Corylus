 # 加载必要的 R 包
library(openxlsx) 
library(raster)

# 设置工作目录
setwd("C:\\Users\\16120\\Desktop\\CC\\envdata")

# 读取采样点数据
locations <- read.csv("for_HKA.csv")

# 确保列名正确
colnames(locations) <- c("Sample", "Longitude", "Latitude")

# 设置经纬度作为坐标
coordinates(locations) <- c("Longitude", "Latitude")

# 读取所有 BIO 变量
bio_list <- list()
for (i in 1:12) {
  bio_list[[i]] <- raster(paste0("D:\\arcgis\\wc2.1_2.5m_srad\\wc2.1_2.5m_srad_", i, ".tif"))
}


# 提取 BIO 数据
bio_results <- data.frame(Sample = locations$Sample, 
                          Longitude = coordinates(locations)[,1], 
                          Latitude = coordinates(locations)[,2])

for (i in 1:12) {
  bio_results[[paste0("srad", i)]] <- extract(bio_list[[i]], locations)
}

# 保存为 TXT 文件
write.table(bio_results, "srad_results.txt", sep = ",", quote = FALSE, row.names = FALSE, col.names = TRUE)

print("✅ 数据提取完成，已保存为 wind_results.txt")
















