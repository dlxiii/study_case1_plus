#!/bin/bash
gdal_grid -l cr_m03_08 -zfield field_3 -a invdistnn:power=2.0:smothing=0.0:radius=600.000000:max_points=12:min_points=0:nodata=-9999.0 -ot Float32 -of GTiff cr_m03_08.vrt cr_m03_08.tif
gdal_contour -b 1 -a ELEV -i 1.0 -f "ESRI Shapefile" cr_m03_08.tif cr_m03_08.shp
