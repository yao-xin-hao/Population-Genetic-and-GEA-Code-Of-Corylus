########### IBD, IBE, pIBD and pIBE for adaptive and neutral loci ############
setwd("C:/Users/16120/desktop/适应/第一部分/IBD/CC")

#remotes::install_version("cowplot", version = "1.1.1")

#install.packages("ggplot2")
rm(list = ls())
library(vegan)
library(geosphere)
library(ggplot2)
library(cowplot)

# 读取环境数据和 FST 矩阵
env = read.csv("group_bio.csv", head = T, row.names = 1)
fst_adaptive = read.table("adaptive_fst_matrix.txt", head = T, sep = "\t", row.names = 1)
fst_neutral = read.table("neutral_fst_matrix.txt", head = T, sep = "\t", row.names = 1)

### 环境距离，c(3:30)需要修改为实际的
ENV = as.data.frame(env[, c(3:30)])
ENV <- scale(ENV, center = TRUE, scale = TRUE)

env_dist = vegdist(ENV, method = "euclidean", binary = FALSE, diag = FALSE, upper = FALSE, na.rm = FALSE)
write.csv(as.matrix(env_dist), file = "scale.csv", quote = F)

#### 地理距离
dist = as.data.frame(env[, c(2:3)])

geo_dist = distm(dist, fun = distVincentyEllipsoid)
rownames(geo_dist) = row.names(dist)
colnames(geo_dist) = row.names(dist)
write.csv(as.matrix(geo_dist), file = "geo_dist.csv", quote = F)

#### Mantel 检验
env_dist = as.matrix(env_dist)
geo_dist = as.matrix(geo_dist)

# Adaptive FST 检验
mantel_adaptive_geo = mantel(fst_adaptive, geo_dist, method = "pearson", permutations = 999)
mantel_adaptive_env = mantel(fst_adaptive, env_dist, method = "pearson", permutations = 999)

# Neutral FST 检验
mantel_neutral_geo = mantel(fst_neutral, geo_dist, method = "pearson", permutations = 999)
mantel_neutral_env = mantel(fst_neutral, env_dist, method = "pearson", permutations = 999)

# 打印结果
print(mantel_adaptive_geo)
print(mantel_adaptive_env)
print(mantel_neutral_geo)
print(mantel_neutral_env)

##### Partial Mantel 检验
# Adaptive FST
mantel_adaptive_env_partial = mantel.partial(fst_adaptive, env_dist, geo_dist, method = "pearson", permutations = 999)
mantel_adaptive_geo_partial = mantel.partial(fst_adaptive, geo_dist, env_dist, method = "pearson", permutations = 999)

# Neutral FST
mantel_neutral_env_partial = mantel.partial(fst_neutral, env_dist, geo_dist, method = "pearson", permutations = 999)
mantel_neutral_geo_partial = mantel.partial(fst_neutral, geo_dist, env_dist, method = "pearson", permutations = 999)

# 打印 Partial Mantel 检验结果
print(mantel_adaptive_env_partial)
print(mantel_adaptive_geo_partial)
print(mantel_neutral_env_partial)
print(mantel_neutral_geo_partial)

############### 绘图 ######################

# 准备数据
geo_dit = read.csv("geo_dist.csv", head = F)
env_dist = read.csv("scale.csv", head = F)
fst_adaptive_raw = read.table("adaptive_fst_matrix.txt", head = F, sep = "\t")
fst_neutral_raw = read.table("neutral_fst_matrix.txt", head = F, sep = "\t")

trans <- function(raw_data) {
  raw_data = raw_data[-1, -1]
  out_data = data.frame(raw_data[, 1])
  colnames(out_data) = "value"
#这里也要修改为实际的52
  for (i in 2:52) {
    temp = data.frame(raw_data[i:52, i])
    colnames(temp) = "value"
    out_data = rbind(out_data, temp)
  }
  out_data = na.omit(out_data)
  return(out_data)
}

#nrow = 1378也许要修改为实际的scale的行数-1
plot_data = as.data.frame(matrix(nrow = 1378, ncol = 0))
plot_data$geo_dit = trans(geo_dit)$value
plot_data$geo_dit = as.numeric(plot_data$geo_dit) / 100000
plot_data$env_dist = trans(env_dist)$value
plot_data$fst_adaptive = trans(fst_adaptive_raw)$value
plot_data$fst_neutral = trans(fst_neutral_raw)$value
colnames(plot_data) = c("geo_dit", "env_dist", "fst_adaptive", "fst_neutral")
write.csv(plot_data, file = "plot_data.csv", quote = F, row.names = F)

plot_data = read.csv("plot_data.csv", head = T)

# 添加 Mantel 统计结果到图注

adaptive_geo_text = paste0("Mantel's r = ", round(mantel_adaptive_geo$statistic, 3), 
                           "\nMantel's p = ", round(mantel_adaptive_geo$signif, 3))
adaptive_env_text = paste0("partial Mantel's r = ", round(mantel_adaptive_env_partial$statistic, 3), 
                           "\npartial Mantel's p = ", round(mantel_adaptive_env_partial$signif, 3))
neutral_geo_text = paste0("Mantel's r = ", round(mantel_neutral_geo$statistic, 3), 
                          "\nMantel's p = ", round(mantel_neutral_geo_partial$signif, 3))
neutral_env_text = paste0("partial Mantel's r = ", round(mantel_neutral_env_partial$statistic, 3), 
                          "\npartial Mantel's p = ", round(mantel_neutral_env$signif, 3))

# 地理距离 vs FST
p1 = ggplot(plot_data) +
  geom_point(aes(x = geo_dit, y = fst_adaptive), size = 3, alpha = 0.7, color = "black", shape = 21, fill = "#FF6347") +
  geom_point(aes(x = geo_dit, y = fst_neutral), size = 3, alpha = 0.7, color = "black", shape = 21, fill = "#CCCCCC") +
  geom_smooth(aes(x = geo_dit, y = fst_neutral), alpha = 0.7, formula = y ~ x, method = lm, se = T, level = 0.95,
              color = "#9c9c9c", fill = "#d6d6d6", size = 1.5, fullrange = F) +
  geom_smooth(aes(x = geo_dit, y = fst_adaptive), alpha = 0.7, formula = y ~ x, method = lm, se = T, level = 0.95,
              color = "#FF6347", fill = "#FFC0CB", fullrange = F, size = 1.5) +
  annotate("text", x = max(plot_data$geo_dit) * 0.6, y = max(plot_data$fst_adaptive) * 0.9,
           label = paste0(adaptive_geo_text, "\n", neutral_geo_text), size = 4, color = "black", hjust = 0) +
  labs(x = "Geographical Distance (100km)", y = expression(italic(F)[italic(ST)]/(1-italic(F)[italic(ST)])), size = 5.5) +
  theme_bw()

# 环境距离 vs FST
p2 = ggplot(plot_data) +
  geom_point(aes(x = env_dist, y = fst_adaptive), size = 3, alpha = 0.7, color = "black", shape = 21, fill = "#FF6347") +
  geom_point(aes(x = env_dist, y = fst_neutral), size = 3, alpha = 0.7, color = "black", shape = 21, fill = "#CCCCCC") +
  geom_smooth(aes(x = env_dist, y = fst_neutral), alpha = 0.7, formula = y ~ x, method = lm, se = T, level = 0.95,
              color = "#9c9c9c", fill = "#d6d6d6", size = 1.5, fullrange = F) +
  geom_smooth(aes(x = env_dist, y = fst_adaptive), alpha = 0.7, formula = y ~ x, method = lm, se = T, level = 0.95,
              color = "#FF6347", fill = "#FFC0CB", fullrange = F, size = 1.5) +
  annotate("text", x = max(plot_data$env_dist) * 0.6, y = max(plot_data$fst_adaptive) * 0.9,
           label = paste0(adaptive_env_text, "\n", neutral_env_text), size = 4, color = "black", hjust = 0) +
  labs(x = "Environment Distance", y = expression(italic(F)[italic(ST)]/(1-italic(F)[italic(ST)])), size = 5.5) +
  theme_bw()

# 合并图表
all = plot_grid(p1, p2, align = "h", labels = c("a", "b"), label_size = 20, ncol = 1)
ggsave(all, file = "P32.pdf", width = 5.5, height = 8)





