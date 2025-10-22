#1. Install GeoLink 
setwd("C:/Users/wb200957/OneDrive - WBG/DEC/SAE/Workshops/code")
rm(list=ls())
library(devtools)
library(tidyverse)
library(sf)
library(haven)
# install from github 
#devtools::install_github("SSA-Statistical-Team-Projects/GeoLink")
# Local install as a backup 
#install.packages("C:/Users/wb200957/OneDrive - WBG/DEC/Github projects/GeoLink", repos = NULL, type = "source")

library(GeoLink) 

# 2. Load MWI shapefile 
shp_dt <- read_sf("./data/mw4.shp")


#3. Get estimated worldpop population and drop unpopulated grids 
population_ea <- GeoLink:::process_raster(shp_dt=shp_dt,raster_file="./data/",
                                                                extract_fun="sum",grid_size=NULL)
population_ea <- population_grid |>
  rename(population = geolink_feature)

write_dta(population_ea,file="mwi_pop")
