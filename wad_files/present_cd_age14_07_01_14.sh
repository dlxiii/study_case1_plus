#!/bin/bash
gdal_grid -l present_cd_age14_07_01_14 -zfield field_3 -a invdistnn:power=2.0:smothing=0.0:radius=600.000000:max_points=12:min_points=0:nodata=-9999.0 -ot Float32 -of GTiff present_cd_age14_07_01_14.vrt present_cd_age14_07_01_14.tif --config GDAL_NUM_THREADS ALL_CPUS
gdal_contour -b 1 -a ELEV -i 1.0 -f "ESRI Shapefile" present_cd_age14_07_01_14.tif present_cd_age14_07_01_14.shp
