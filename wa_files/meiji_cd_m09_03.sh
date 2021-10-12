#!/bin/bash
gdal_grid -l meiji_cd_m09_03 -zfield field_3 -a invdistnn:power=2.0:smothing=0.0:radius=600.000000:max_points=12:min_points=0:nodata=-9999.0 -ot Float32 -of GTiff meiji_cd_m09_03.vrt meiji_cd_m09_03.tif
gdal_contour -b 1 -a ELEV -i 1.0 -f "ESRI Shapefile" meiji_cd_m09_03.tif meiji_cd_m09_03.shp
