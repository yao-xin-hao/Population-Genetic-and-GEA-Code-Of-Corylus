library(psych)
library(vegan)
library(data.table)

args <- commandArgs(TRUE)
gen_file=args[1]
env_file=args[2]
z_bin=as.numeric(args[3])
#chr_12314_T  snp_name_start则输入chr
snp_name_start=args[4] # 若全是需要的位点，或没有统一的snp前缀，请输入 0
#use_signif_axis=1
use_signif_axis=0
if (length(args)==5 & as.numeric(args[5])==0){
    use_signif_axis=0
}

#读取太慢---
#gen <- read.csv(gen_file,header = T,row.names = 2)
#gen <- gen[,6:length(gen[1,])] #第一列会读进来，矩阵中没有第二列
#----

#新读取---
if (! file.exists("gene1.RData")){
    gen <- fread(gen_file,sep=',',stringsAsFactors = F, na.strings = "", data.table = F,header=T)
    rownames(gen) <- gen$IID
    gen <- gen[,7:length(gen[1,])]
    #----
    gen.imp <- apply(gen, 2, function(x) replace(x, is.na(x), as.numeric(names(which.max(table(x)))))) #去除NA
    if (snp_name_start == '0' | snp_name_start == 0) {
	        colnames(gen.imp) <- paste0('Chr',colnames(gen.imp))
    }
    save.image("gene1.RData")
    save(gen.imp,file="gene1.RData")
}else{
    load("gene1.RData")
}

env <- read.csv(env_file,header = T)
env[,1] <- as.character(env[,1])
if (identical(rownames(gen.imp), env[,1]) != T ) {
    print("the sample order in gen and env is not ture")
    quit()
}else{ 
    print("yes")
}

pred <- env[,5:length(env[1,])]
env_num=length(pred[1,])

if (! file.exists("wolf.rda.RData")){
    wolf.rda <- rda(gen.imp ~ ., data=pred, scale=T)
    #wolf.rda
    write.table(wolf.rda$CCA$v,file="RDA.load.txt",sep = "\t",row.names = T)

    #RsquareAdj(wolf.rda)
    #summary(eigenvals(wolf.rda, model = "constrained"))

    png(file="screeplot_pda.png")
    screeplot(wolf.rda)
    dev.off()

    #评估模型
    #个体太多就没办法做评估
    #signif.full <- anova.cca(wolf.rda, parallel=getOption("mc.cores"))
    #此步为多线程 300个个体，7个环境因子，10000个snp使用

    #signif.full
    #if (signif.full$"Pr(>F)"[1]>=0.015){
    #    print("warning:model is not suit")
    #    #quit()
    #}

    #评估约束轴
    if (use_signif_axis==1){
	signif.axis <- anova.cca(wolf.rda, by="axis", parallel=getOption("mc.cores"))
    }else{
	signif.axis <- 'all'
    }
    #signif.axis

    save.image("wolf.rda.RData")
    save(wolf.rda,signif.axis,file="wolf.rda.RData")
}else{
    load("wolf.rda.RData")
}
wolf.rda
RsquareAdj(wolf.rda)
summary(eigenvals(wolf.rda, model = "constrained"))
#signif.full
signif.axis

#选择显著RDA
if (signif.axis=='all'){
    RDA_num=1:env_num
}else{
    RDA_num <- c()
    for (i in c(1:env_num)){
	if (signif.axis$"Pr(>F)"[i] <0.02){
	    RDA_num <- c(RDA_num,i)
	}
    }
}

if (length(RDA_num)==0){
    print("The RDA is not suit")
    quit()
}
sprintf("We chose RDA%s",RDA_num)

# checking Variance Inflation Factors for the predictor variables used in the model

Inflation <- vif.cca(wolf.rda)
print(Inflation)
if (length(Inflation[Inflation>10]) > 0){
    print("下列几个环境因子膨胀因子高于10，请删除共线关系高的环境因子")
    names(Inflation[Inflation>10])
    #quit()
}

family=unique(env[,2])
family_num=length(family)
levels(env[,2])<- family
eco <- factor(env[,2])
#暂时为组数限制在6各以内，若想怎加，添加RGB颜色即可
bg <- c("#ff7f00","#1f78b4","#ffff33","#a6cee3","#33a02c","#e31a1c")[1:family_num]

plot.sample_with_env <- function(one_,two_){
    plot(wolf.rda, type="n", scaling=3, choices=c(one_,two_))
    #points(wolf.rda, display="species", pch=20, cex=0.7, col="gray32", scaling=3,choices = c(one_,two_))
    points(wolf.rda, display="sites", pch=21, cex=1.3, col="gray32", scaling=3, bg=bg[eco],choices = c(one_,two_))
    text(wolf.rda, scaling=3, display="bp", col="#0868ac", cex=1,choices = c(one_,two_))
    legend("bottomright", legend=levels(eco), bty="n", col="gray32", pch=21, cex=1, pt.bg=bg)
}

if (length(RDA_num) >= 2){
    m=0
    for (i in c(2:length(RDA_num))){
	m=m+1
	pdf_=paste("sample_with_env",m,".pdf",sep="")
	pdf(file=pdf_)
	plot.sample_with_env(RDA_num[1],RDA_num[i])
	dev.off()
    }
}else{
    pdf_="sample_with_env1.pdf"
    pdf(file=pdf_)
    plot.sample_with_env(1,2)
    dev.off()
}

pdf(file="loading_on_RDA.pdf")
load.rda <- scores(wolf.rda, choices=c(1:RDA_num[length(RDA_num)]), display="species")
write.table(load.rda,file="RDA.load.score.txt",sep = "\t",row.names = T,quote = F)

for (i in RDA_num){
    main_=paste("Loadings on RDA",i,sep="")
    hist(load.rda[,i], main=main_)
}
dev.off()

save.image("RDA2.RData")
save(env,pred,env_num,wolf.rda,signif.axis,RDA_num,Inflation,family,family_num,eco,bg,plot.sample_with_env,load.rda,file="RDA2.RData")

#z为多少个标准差
#这里基于的是正太分布，如果loading_on_RDA.pdf 中的RDA约束轴不满足正太，请用其他方式提取异常值
outliers <- function(x,z){
    lims <- mean(x) + c(-1, 1) * z * sd(x)
    x[x < lims[1] | x > lims[2]]
}

cand <- data.frame(0,0,0)
ncand=0
colnames(cand) <- c("axis","snp","loading")
for (i in RDA_num){
    cand_ <- outliers(load.rda[,i],z_bin)
    #双尾 1.96==0.95 2==0.9543 2.576==0.99 3==0.9973 
    if (length(cand_)==0){
	RDA_num <- RDA_num[-which(RDA_num==i)]
	next
    }
    ncand <- ncand+length(cand_)
    cand_ <- cbind.data.frame(rep(i,times=length(cand_)), names(cand_), unname(cand_))
    colnames(cand_) <- c("axis","snp","loading")
    cand <- rbind(cand,cand_)
}
if (length(RDA_num)==0){
    print("there is no snp selceted,you can extend you snp or chose lower z-value")
    quit()
}
cand <-cand[-1,]
cand$snp <- as.character(cand$snp)

#colnames(pred)
foo <- matrix(nrow=(ncand), ncol=env_num)
colnames(foo) <- colnames(pred)

for (i in 1:length(cand$snp)) {
    nam <- cand[i,2]
    snp.gen <- gen.imp[,nam]
    foo[i,] <- apply(pred,2,function(x) cor(x,snp.gen))
}

cand <- cbind.data.frame(cand,foo)
cand <- cand[!duplicated(cand$snp),]
for (i in 1:length(cand$snp)) {
    bar <- cand[i,]
    cand[i,env_num+4] <- names(which.max(abs(bar[4:env_num+3])))
    cand[i,env_num+5] <- max(abs(bar[4:env_num+3]))
}
colnames(cand)[env_num+4] <- "predictor"
colnames(cand)[env_num+5] <- "correlation"
write.csv(cand,file="select_snp_cor_enviromen.csv",row.names = F,quote = F)

table(cand$predictor)

clolor_2<-c("#a6cee3","#1f78b4","#b2df8a","#33a02c","#fb9a99","#e31a1c","#fdbf6f","#ff7f00","#cab2d6","#6a3d9a","#ffff99","#b15928")
sel <- cand$snp
env <- cand$predictor
env_uni <- unique(env)
for (i in 1:length(env_uni)){
    env[env==env_uni[i]] <- clolor_2[i]
}

col.pred <- rownames(wolf.rda$CCA$v)

for (i in 1:length(sel)) {
    foo <- match(sel[i],col.pred)
    col.pred[foo] <- env[i]
}

if (snp_name_start=='0' | snp_name_start==0){
    col.pred[grep('Chr',col.pred)] <- '#f1eef6'
}else{
    col.pred[grep(snp_name_start,col.pred)] <- '#f1eef6' #如果你的snp名称不是以chr为开头，请更改
}
empty <- col.pred
empty[grep("#f1eef6",empty)] <- rgb(0,1,0, alpha=0)
empty.outline <- ifelse(empty=="#00FF0000","#00FF0000","gray32")
bg2 <- clolor_2[1:length(env_uni)]

plot.SNPS <- function(one_,two_){
    plot(wolf.rda, type="n", scaling=3, xlim=c(-1,1), ylim=c(-1,1), choices=c(one_,two_))
    points(wolf.rda, display="species", pch=21, cex=1, col="gray32", bg=col.pred, scaling=3, choices=c(one_,two_))
    points(wolf.rda, display="species", pch=21, cex=1, col=empty.outline, bg=empty, scaling=3, choices=c(one_,two_))
    text(wolf.rda, scaling=3, display="bp", col="#0868ac", cex=1, choices=c(one_,two_))
    legend("bottomright", legend=env_uni, bty="n", col="gray32", pch=21, cex=1, pt.bg=bg2)
}

if (length(RDA_num) >= 2){
    m=0
    for (i in c(2:length(RDA_num))){
	m=m+1
        pdf_=paste("select_snps",m,".pdf",sep="")
	pdf(file=pdf_)
	plot.SNPS(RDA_num[1],RDA_num[i])
	dev.off()
    }
}else{
    pdf_="select_snps1.pdf"
    pdf(file=pdf_)
    plot.SNPS(1,2)
    dev.off()
}

save.image("RDA3.RData")
save(outliers,cand,ncand,foo,clolor_2,sel,env,env_uni,col.pred,empty,empty.outline,bg2,plot.SNPS,file="RDA3.RData")

print("all done")
