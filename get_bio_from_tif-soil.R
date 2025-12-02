#install.packages("raster")
#install.packages("openxlsx")
library(openxlsx) 
library(raster)
#
setwd("C:\\Users\\16120\\Desktop\\CC\\envdata")
locations <- read.csv("for_HKA.csv")
coordinates(locations)=c("Longtitude","Latitude")
locations
write.table(locations,"sample_id.txt", sep = "\t", quote=F,row.names = T,col.names=T)

#
AWC <- raster("D:\\arcgis\\wc_土壤\\China\\AWC.tif")
CEC <- raster("D:\\arcgis\\wc_土壤\\China\\CEC_SOIL.tif")
PH <- raster("D:\\arcgis\\wc_土壤\\China\\PH.tif")
TEB <- raster("D:\\arcgis\\wc_土壤\\China\\TEB.tif")
total_N <- raster("D:\\arcgis\\wc_土壤\\China\\total_N.tif")



#
res_AWC <- extract(x = AWC, y = locations)
res_CEC <- extract(x = CEC, y = locations)
res_PH <- extract(x = PH, y = locations)
res_TEB <- extract(x = TEB, y = locations)
res_total_N <- extract(x = total_N, y = locations)


#
write.table(res_AWC,"res_AWC.txt", sep = "\t", quote=F,row.names = T,col.names=T)
write.table(res_CEC,"res_CEC.txt", sep = "\t", quote=F,row.names = T,col.names=T)
write.table(res_PH,"res_PH.txt", sep = "\t", quote=F,row.names = T,col.names=T)
write.table(res_TEB,"res_TEB.txt", sep = "\t", quote=F,row.names = T,col.names=T)
write.table(res_total_N,"res_total_N.txt", sep = "\t", quote=F,row.names = T,col.names=T)
