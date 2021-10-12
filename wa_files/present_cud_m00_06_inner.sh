#!/bin/bash
gdal_grid -l present_cud_m00_06_inner -zfield field_3 -a invdistnn:power=2.0:smothing=0.0:radius=600.000000:max_points=12:min_points=0:nodata=-9999.0 -ot Float32 -of GTiff present_cud_m00_06_inner.vrt present_cud_m00_06_inner.tif --config GDAL_NUM_THREADS ALL_CPUS
gdal_contour -b 1 -a ELEV -i 1.0 -f "ESRI Shapefile" present_cud_m00_06_inner.tif present_cud_m00_06_inner.shp
