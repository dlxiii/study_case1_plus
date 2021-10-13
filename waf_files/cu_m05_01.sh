#!/bin/bash
gdal_grid -l cu_m05_01 -zfield field_3 -a invdistnn:power=2.0:smothing=0.0:radius=600.000000:max_points=12:min_points=0:nodata=-9999.0 -ot Float32 -of GTiff cu_m05_01.vrt cu_m05_01.tif
gdal_contour -b 1 -a ELEV -i 1.0 -f "ESRI Shapefile" cu_m05_01.tif cu_m05_01.shp
