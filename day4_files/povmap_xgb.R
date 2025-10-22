rm(list=ls())
library("haven");
library("povmap");
library("tidyverse")
setwd("C:/Users/wb200957/OneDrive - WBG/DEC/SAE/Workshops/code");
pop <- as_factor(as.data.frame(read_dta("./data/pop.dta")));
smp <- as_factor(as.data.frame(read_dta("./data/sample.dta")));
smp <- smp[,c("ea_code","poor","total_weights")]
smp <- left_join(smp,pop) 
model <- as.formula(paste("poor ~",colnames(smp)[4:503],collapse=" + "))
xgb_results <- povmap:::xgb(fixed = model,pop_data = pop, smp_data=smp,
domains = "ta_code", sub_domains="ea_code",pop_weight="population",
transformation="no",      na.rm=T,weightedBS=T, center_residuals=T,
objective = "reg:logistic"
)
write.excel(xgb_results, file = "xgb_output.xlsx", indicator = "all", MSE = TRUE, CV = TRUE)
save(xgb_results,file="xgb_output")
