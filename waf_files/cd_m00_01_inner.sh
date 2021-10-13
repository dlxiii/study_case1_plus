#!/bin/bash
gdal_grid -l cd_m00_01_inner -zfield field_3 -a invdistnn:power=2.0:smothing=0.0:radius=600.000000:max_points=12:min_points=0:nodata=-9999.0 -ot Float32 -of GTiff cd_m00_01_inner.vrt cd_m00_01_inner.tif --config GDAL_NUM_THREADS ALL_CPUS
gdal_contour -b 1 -a ELEV -i 1.0 -f "ESRI Shapefile" cd_m00_01_inner.tif cd_m00_01_inner.shp
