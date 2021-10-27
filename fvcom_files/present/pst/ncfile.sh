#!/bin/bash

matlab -nodisplay < ncfile_rho1.m
matlab -nodisplay < ncfile_u.m
matlab -nodisplay < ncfile_v.m
matlab -nodisplay < ncfile_temp.m
matlab -nodisplay < ncfile_salinity.m
matlab -nodisplay < ncfile_strhouv.m