#!/bin/bash
gdal_grid -l present_cd_spr_07_inner -zfield field_3 -a invdistnn:power=2.0:smothing=0.0:radius=600.000000:max_points=12:min_points=0:nodata=-9999.0 -ot Float32 -of GTiff present_cd_spr_07_inner.vrt present_cd_spr_07_inner.tif
gdal_contour -b 1 -a ELEV -i 1.0 -f "ESRI Shapefile" present_cd_spr_07_inner.tif present_cd_spr_07_inner.shp
