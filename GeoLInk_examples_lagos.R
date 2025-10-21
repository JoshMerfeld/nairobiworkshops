#1. Install GeoLink 
setwd("C:/Users/wb200957/OneDrive - WBG/DEC/SAE/Workshops/code")
rm(list=ls())
library(devtools)
library(tidyverse)
library(sf)
# install from github 
#devtools::install_github("SSA-Statistical-Team-Projects/GeoLink")
# Local install as a backup 
#install.packages("C:/Users/wb200957/OneDrive - WBG/DEC/Github projects/GeoLink", repos = NULL, type = "source")

library(GeoLink) 

# 2. Load NGA shapefile (which comes with package), 
#restrict to Lagos,province, and generate grid 
data(shp_dt)
shp_dt <- shp_dt[shp_dt$ADM1_EN == "Lagos",]
shp_dt <- st_transform(shp_dt,5070)

grid <- gengrid2(
  shp_dt=shp_dt,
  grid_size = 1000,
  sqr = TRUE
)

#3. Get estimated worldpop population and drop unpopulated grids 
population_grid <- GeoLink:::process_raster(shp_dt=grid,raster_file="./data/NGA_population_v3_0_gridded.tif",
                                                                extract_fun="sum",grid_size=NULL)
population_grid <- population_grid |>
  rename(population = geolink_feature)

grid <- grid[population_grid$population>0,]
population_grid <- population_grid[population_grid$population>0,]
saveRDS(grid,file="grid")
grid <- readRDS("grid")

#4. Obtain mean night tine lights for each grid 
ntl_grid <- geolink_ntl(
  username = "davidn10", 
  password = "Logmeon123456!",
    time_unit = "annual",
  start_date = "2022-01-01",
  end_date = "2022-12-31",
    shp_dt = grid
)

#5. Obtain worldpop building data for each grid 
geolink_buildings_grid <- geolink_buildings(iso_code = "NGA",
                                            version = "v1.1",
                                            shp_dt = grid) 

#6. obtain NDVI for each grid 
geolink_ndvi_grid <- geolink_vegindex(
  shp_dt = grid,
  start_date="2022-01-01",
  end_date="2022-12-31"
) 

#Take mean ndvi across monthly values 
geolink_ndvi_grid <- st_drop_geometry(geolink_ndvi_grid)
indices <- grepl(pattern = "^ndvi_y2022_m*", x=colnames(geolink_ndvi_grid)) 
geolink_ndvi_grid[,"ndvi_y2022"]  <- rowMeans(geolink_ndvi_grid[,indices])
geolink_ndvi_grid <- geolink_ndvi_grid[,!indices]

#7. Pollution 
geolink_pollution_o3_grid <- geolink_pollution(
  start_date="2022-01-01",
  end_date="2022-12-31", 
  indicator = "o3",
  shp_dt = grid) 

#Take mean pollution across monthly values 
geolink_pollution_o3_grid$o3_y2022_m6 <- NULL
geolink_pollution_o3_grid <- st_drop_geometry(geolink_pollution_o3_grid)
indices <- grepl(pattern = "^o3_y2022_m*", x=colnames(geolink_pollution_o3_grid)) 
geolink_pollution_o3_grid[,"o3_y2022"]  <- rowMeans(geolink_pollution_o3_grid[,indices])
geolink_pollution_o3_grid <- geolink_pollution_o3_grid[,!indices]

#8. cell towers 
#Download NGA file from opencellid. It's called 621.csv.gz 

geolink_cell_grid <- geolink_opencellid(
  cell_tower_file = "./data/621.csv.gz",
  shp_dt = grid) 

# calculate distance from each grid to nearest cell tower 
geolink_cell_grid <- st_as_sf(cbind(geolink_cell_grid,grid$geometry))
cell_towers <- st_as_sf(geolink_cell_grid[geolink_cell_grid$cell_towers>0,])
nearest_indices <- st_nearest_feature(geolink_cell_grid,cell_towers)        
geolink_cell_grid$distance_nearest_tower <- st_distance(geolink_cell_grid, cell_towers[nearest_indices, ], by_element = TRUE)

#9. Land cover classifications 
geolink_land_grid <- geolink_landcover(
  shp_dt = grid,
  start_date="2022-01-01",
  end_date="2022-12-31"
  ) 





#11. Putting it all together 
data <- list(population_grid,ntl_grid,geolink_buildings_grid,geolink_ndvi_grid,geolink_pollution_o3_grid,geolink_cell_grid,geolink_land_grid)

for (x in data[data!="population_grid"]) {
  x <- st_drop_geometry(x)
}
population_grid <- select(population_grid,c("poly_id","ADM2_EN","ADM2_PCODE","population"))
ntl_grid <- select(ntl_grid,"ntl_mean") 
geolink_buildings_grid <- select(geolink_buildings_grid,"count":"urban")
geolink_ndvi_grid <- select(geolink_ndvi_grid,"ndvi_y2022")
geolink_pollution_o3_grid <- select(geolink_pollution_o3_grid,"o3_y2022")
geolink_cell_gid <- select(geolink_cell_grid,c("cell_towers","distance_nearest_tower"))
geolink_land_grid <- select(geolink_land_grid,"water":"rangeland")

features <- do.call(cbind,data)
saveRDS(features,file="features")
