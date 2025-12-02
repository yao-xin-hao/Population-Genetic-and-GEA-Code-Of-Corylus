library(readr)
library(dplyr)
library(ggplot2)
library(tidyverse)

setwd("C:/Users/16120/Desktop/CC1")
graphics.off()

k1 <- read_delim("Corylus.1.Q.result.ggplot2_data","\t",
                  escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=1) 
k2 <- read_delim("Corylus.2.Q.result.ggplot2_data","\t",
                  escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=2) 
k3 <- read_delim("Corylus.3.Q.result.ggplot2_data","\t",
                 escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=3) 
k4 <- read_delim("Corylus.4.Q.result.ggplot2_data","\t",
                 escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=4)
k5 <- read_delim("Corylus.5.Q.result.ggplot2_data","\t",
                 escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=5)
k6 <- read_delim("Corylus.6.Q.result.ggplot2_data","\t",
                 escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=6)
k7 <- read_delim("Corylus.7.Q.result.ggplot2_data","\t",
                 escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=7)
k8 <- read_delim("Corylus.8.Q.result.ggplot2_data","\t",
                 escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=8)
id <- read.table("pops_samples_structure_sort",sep = "\t",header = F)
colnames(id) <- c("ID","Class")
samples <- factor(id$ID,levels = id$ID)

#k2$k[k2$k=='k2'] <-'k0' 
q <- rbind(k4)
q$id <- factor(q$id,levels = samples)
q$group <- "Cluster"
for (i in 1:length(q$id)){
  q$group[i] <- id$Class[id$ID==q$id[i]]
}


a = q %>% mutate(cname=paste0(max_k,'_',k)) %>% # view()
  select(id, cname, percent) %>%
  spread(key = cname, value = percent) %>%
  column_to_rownames('id') # %>%
#complete(fill = 0)

a[is.na(a)] = 0

#t = a %>% dist() %>% hclust()
#tt = row.names(a)[ t$order ]

#write.table(tt,file = 'tt.txt',sep = "\t")
tt <- read.table("tt.txt",header = F,sep = "\t")$V2

q$k <- factor(q$k)
color1 <- c("#0773B4","#E7A023","#8da0cb","#ffd92f","#a6d854","#fc8d62","#fe2d62","#fc8c22")

pdf("strcuture.pdf",width = 8,height = 4)
q %>%
  mutate(id = factor(id, levels = tt)) %>%
  ggplot(aes(x=id,y=percent,fill=k))+geom_bar(stat='identity',width=1)+
  facet_grid(max_k~group,scales = "free_x", space = "free_x")+
  scale_fill_manual(values = color1)+
  ##facet_graid对x分组，会将每一个id纳入每一个分组内,添加参数scales = "free_x", space = "free_x" 将多余的id去掉
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 1,size=3))+
  #theme(panel.grid.major = element_blank(),panel.grid.minor = element_blank(),
  #      axis.text.y = element_blank(),axis.ticks.y = element_blank())+
  ylab(NULL)+
  xlab("")+
  theme(panel.grid.major =element_blank(), 
        panel.grid.minor = element_blank(),
        panel.background = element_blank())+#delate background
  scale_y_continuous(expand = c(0,0))+ #去除图与坐标间隙，由于x是factor，所以只需要处理y
  theme(axis.line =element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank())+ #移除坐标轴 
  #theme(axis.text.x=element_text(angle=90,hjust=1,size=7))+
  theme(strip.text = element_blank())+  #strip.text 为xy方向的分轴标题
  theme(panel.spacing.x=unit(0.02, "lines"), 
        panel.spacing.y=unit(0.3, "lines"))+#分图间隔
  theme(legend.position="none")
  #theme(aspect.ratio = 7 / 9) 这个方法用不了这个
dev.off()

###############################################群体画线##################################################
library(readr)
library(dplyr)
library(ggplot2)
library(tidyverse)

setwd("C:/Users/16120/Desktop/CY1")
graphics.off()

k1 <- read_delim("Corylus.1.Q.result.ggplot2_data","\t",
                  escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=1) 
k2 <- read_delim("Corylus.2.Q.result.ggplot2_data","\t",
                  escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=2) 
k3 <- read_delim("Corylus.3.Q.result.ggplot2_data","\t",
                 escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=3) 
k4 <- read_delim("Corylus.4.Q.result.ggplot2_data","\t",
                 escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=4)
k5 <- read_delim("Corylus.5.Q.result.ggplot2_data","\t",
                 escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=5)
k6 <- read_delim("Corylus.6.Q.result.ggplot2_data","\t",
                 escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=6)
k7 <- read_delim("Corylus.7.Q.result.ggplot2_data","\t",
                 escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=7)
k8 <- read_delim("Corylus.8.Q.result.ggplot2_data","\t",
                 escape_double=FALSE,trim_ws=TRUE) %>% mutate(max_k=8)
id <- read.table("pops_samples_structure_sort",sep = "\t",header = F)
colnames(id) <- c("ID","Class")
samples <- factor(id$ID,levels = id$ID)

#k2$k[k2$k=='k2'] <-'k0' 
q <- rbind(k2)


q$id <- factor(q$id,levels = samples)
q$group <- "Cluster"
for (i in 1:length(q$id)){
  q$group[i] <- id$Class[id$ID==q$id[i]]
}


a = q %>% mutate(cname=paste0(max_k,'_',k)) %>% # view()
  select(id, cname, percent) %>%
  spread(key = cname, value = percent) %>%
  column_to_rownames('id') # %>%
#complete(fill = 0)

a[is.na(a)] = 0

t = a %>% dist() %>% hclust()
tt = row.names(a)[ t$order ]

write.table(tt,file = 'tt.txt',sep = "\t")
tt <- read.table("tt2.txt",header = F,sep = "\t")$V2

q$k <- factor(q$k)
#color1 <- c("#0773B4","#E7A023","#8da0cb","#ffd92f","#a6d854","#fc8d62","#6C63AC","#CC79A8")
#color1 <- c("#5491BB","#A194C6","#255FA7","#89BC96","#38823E","#FAAF76","#F16E65","#CA2A33")
#color1 <- c("#FDE526","#88CBEE","#A194C6","#2B798F","#89BC96","#FAAF76","#F16E65","#CA2A33") #CC
color1 <- c("#88CBEE","#FAAF76","#A194C6","#F16E65") #CC k=4
#color1 <- c("#FAAF76","#88CBEE","#F16E65") #k=3,平榛 刺榛
color1 <- c("#88CBEE","#FAAF76","#F16E65")
color1 <- c("#88CBEE","#F16E65","#FAAF76")
color1 <- c("#FAAF76","#88CBEE","#F16E65")
color1 <- c("#FAAF76","#F16E65","#88CBEE") #cfe1
#color1 <- c("#F16E65","#88CBEE","#FAAF76") #k=3

color1 <- c("#88CBEE","#FAAF76") #k=2 滇榛 披针叶榛
color1 <- c("#FAAF76","#88CBEE") #k=2 武陵榛


# 定义需要分割线的 id 和分割线位置
#target_ids <- c("CM54", "CM60", "CM22", "CM10", "CM25", "CM33", "CM17", "CM51", "CM45", "CM12","CM40") #CM
#target_ids <- c("lu242","2013-MZL-104-12","SRR22240370","HP8","lu160","lu165","SRR22240394","lu157","lu63","SRR22240395","lu169","lu170","SRR22240392","SRR22240384","LZ2021026-2","SRR22240383","lu55","SRR22240376","lu60") #CH
#target_ids <- c("SRR26796320","SRR26796384","lu83","CZ62","SRR22240321","SRR22240424","SRR26796339","2014-LZQ050-9","lu138","SRR22240314","lu135","lu134","SRR26796365","2014-LZQ-137-2","lu182","CZ12","2014-LZQ-052-2","HC12","lu216","lu239","lu212","lu207","lu202","lu195","2014-LZH-002-12","SRR22240309") #CS
target_ids <- c("SRR22240404","CZ38","lu94","SRR22240414","HD4","lu93","SRR22240419","lu52","CZ60","lu116","HD3","lu113","lu46","lu107","lu109","CZ61","SRR22240411","lu100","CZ53","HD10") #CY
#target_ids <- c("lu187","lu70","lu186","2014-LZQ-043-9","lu180","lu43","lu39","lu75","lu80","2014-LZQ-014-20","lu221") #CW
#target_ids <- c("CZ33","CZ35","L68","L80","L87","L10","L71","L38","L30","L77","L53","L90","L50","L24","L15","L47","CZ-SCWC02","L41","L27","L56","L18","L83","L74","L33","L65") #CFE
#target_ids <- c("HY25","HH88","FSC6-3","FGS2-3","HY5-1","HY40","FCQ2-2","HY20","HY18","FGS5-5","FSC1-1","HY31","FSX1-3","FSX2-4","HY12","FSC7-2","HY22") #CFA
#target_ids <- c("CYN4-6","HH32", "CYN5-7","CYN2-5","CZ37","HH48","CZ42","CCH00","CYN1-2","CYN1-6","CZ28","CHB1-5","HH97","CZ31","HH53","CSC12-2","CSC9-1","CGZ1-4","HH7-1","CHN1-5","SRR26796373","HH145","CCQ1-1","HH149","CGZ3-6","CGZ3-4","HH56","HH155","CZ27","HH59","SRR26815615","HH141","HH64","SRR26815620","CSC5-2","HH128","HH131","CSC4-4","lu179","HH2","HH124","HH67","SRR26815622","CSC1-1","CGS1-4","HH115","HH119","HH39","HH29","HH159","CSX5-7","HH113","HY15") #CC

line_positions <- which(tt %in% target_ids) - 0.5  # 计算分割线位置 (id 后面)
graphics.off()
# 生成图形并绘制分割线
pdf("structure4.pdf", width = 30, height = 2)
q %>%
  mutate(id = factor(id, levels = tt)) %>%
  ggplot(aes(x = id, y = percent, fill = k)) +
  geom_bar(stat = 'identity', width = 1) +
  facet_grid(max_k ~ group, scales = "free_x", space = "free_x") +
  scale_fill_manual(values = color1) +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 1, size = 3),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_blank(),
    strip.text = element_blank(),
    legend.position = "none",
    panel.spacing.x = unit(0.02, "lines"),
    panel.spacing.y = unit(0.3, "lines"),
    axis.line = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks = element_blank()
  ) +
  scale_y_continuous(expand = c(0, 0)) +
  # 动态绘制多条分割线
  geom_segment(data = data.frame(x = line_positions, 
                                 xend = line_positions, 
                                 y = 0, 
                                 yend = 1),
               aes(x = x, xend = xend, y = y, yend = yend),
               inherit.aes = FALSE, color = "black", size = 2)  # 自定义线条样式
dev.off()
 


