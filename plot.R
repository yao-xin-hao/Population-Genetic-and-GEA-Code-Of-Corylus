library("CMplot")
pmap <- read.table("GK.pmap", header = F)
pmap$V4[is.infinite(pmap$V4)] <- NA
pmap <- na.omit(pmap)
CMplot(pmap,col=c("#1D4989","#6692C8"), threshold =c(5.3755464242940295e-08),threshold.col=("grey"),threshold.lty=c(2), threshold.lwd=c(1), amplify = F, file = "tiff",width=14,height=6 ,plot.type=c("m","q"))
