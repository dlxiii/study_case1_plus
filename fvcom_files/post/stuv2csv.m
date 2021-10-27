clear all;
clearvars; 
clc;

delete('diary')
diary on;
% Which system am I using?
if ismac        % On Mac
    basedir = '/Users/yulong/GitHub/';
    addpath([basedir,'fvcomtoolbox/custom/']);
    addpath([basedir,'fvcomtoolbox/utilities/']);
elseif isunix	% Unix?
    basedir = '/home/usr0/n70110d/';
    addpath([basedir,'github/fvcomtoolbox/custom/']);
    addpath([basedir,'github/fvcomtoolbox/utilities/']);
elseif ispc     % Or Windows?
    basedir = 'C:/Users/Yulong WANG/Documents/GitHub/';      
    addpath([basedir,'fvcom-toolbox/custom/']);
    addpath([basedir,'fvcom-toolbox/utilities/']);
end

%%%------------------------------------------------------------------------
%%%                          INPUT CONFIGURATION
%%%------------------------------------------------------------------------
formatSpec = '%02i';
td = load("./strhouv_mesh.mat");
mstrhouv = td.mstrhouv;
clear td;
if exist('../../stuv_files', 'dir')~=7
    mkdir('../../stuv_files')
end

%% present annual layers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
folderpath = {'meiji','present'};
typelist = {'cu','cd','cud','cr'};
% typelist = {'cr'};
layerlist = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20];
month = {'m09','m10','m11','m12',...
    'm01','m02','m03','m04','m05','m06',...
    'm07','m08'};
mmean = {'m00'};
csv_resol = 500;
                    
for f = 1:length(folderpath) 
    otfile_bash = ['../../wa_files/',folderpath{f},'_multi_run_a.sh'];
    info_file = ['../../wa_files/',folderpath{f},'_info_annual_layers.csv'];
    shp_path = ['../../gis_files/',folderpath{f},'/others/boundary_innerbay.shp'];
    fileID0 = fopen(otfile_bash,'w');
    fileID1 = fopen(info_file,'w');
    fprintf(fileID0,'#!/bin/bash\n');
    fprintf(fileID0,'# source /home/usr0/n70110d/usr/local/anaconda3/2019.03.py3/etc/profile.d/conda.sh\n');
    fprintf(fileID0,'# conda activate gdal\n');
    fprintf(fileID0,'\n');
    for c = 1:length(typelist)
        for l = 1:length(layerlist)
            layer = layerlist(l);
            for m = 1:length(mmean)
                data = mwa.(folderpath{f}).(typelist{c}).(mmean{m})(:,:,layer);

                % Create csv
                data_temp.latint = mwa.lat;
                data_temp.lonint = mwa.lon;
                [Y,X] = meshgrid(data_temp.latint,data_temp.lonint);
                M = [reshape(X,[numel(X),1]),...
                    reshape(Y,[numel(Y),1]),...
                    reshape(data,[numel(data),1])];
                if exist('../../wa_files', 'dir')~=7
                    mkdir('../../wa_files')
                end
                  filename = [folderpath{f},'_',typelist{c},'_',mmean{m},'_',num2str(layer,formatSpec)];
                otfile_csv = ['../../wa_files/',...
                     filename,'.csv'];
                fileID = fopen(otfile_csv,'w');
                % fprintf(fileID,'%12s %12s %12s\n','lon,','lat,','age,');
                for i = 1:length(M)
                    fprintf(fileID,'%11.6f%1s %11.6f%1s %11.2f%1s\n',...
                        M(i,1),',',M(i,2),',',M(i,3),',');
                end
                fclose(fileID); 
                
                % average value in polygen
                x = M(:,1); y = M(:,2); z = M(:,3); 
                [~,~,val_age] = valInPol(x,y,z,shp_path);
                fprintf(fileID1,'%s%1s %5.2f%1s\n',...
                        filename,',',nanmean(val_age),',');

                % Create vrt
                otfile_vrt = ['../../wa_files/',...
                     filename,'.vrt'];
                fileID = fopen(otfile_vrt,'w');
                fprintf(fileID,'<OGRVRTDataSource>\n');
                fprintf(fileID,'    <OGRVRTLayer name="%s">\n',filename);
                fprintf(fileID,'        <SrcLayer>%s</SrcLayer>\n',filename);
                fprintf(fileID,'        <LayerSRS>EPSG:4326</LayerSRS>\n');
                fprintf(fileID,'        <SrcDataSource>CSV:%s.csv</SrcDataSource>\n',filename);
                fprintf(fileID,'        <GeometryType>wkbPoint</GeometryType>\n');
                fprintf(fileID,'        <GeometryField encoding="PointFromColumns" x="field_1" y="field_2" z="field_3"/>\n');
                fprintf(fileID,'    </OGRVRTLayer>\n');
                fprintf(fileID,'</OGRVRTDataSource>\n');
                fclose(fileID);

                % Create bash
                otfile_sh = ['../../wa_files/',...
                     filename,'.sh'];
                fileID = fopen(otfile_sh,'w');
                fprintf(fileID,'#!/bin/bash\n');
                fprintf(fileID,'gdal_grid -l %s -zfield field_3 -a invdistnn:power=2.0:smothing=0.0:radius=%f:max_points=12:min_points=0:nodata=-9999.0 -ot Float32 -of GTiff %s.vrt %s.tif --config GDAL_NUM_THREADS ALL_CPUS\n',filename,csv_resol*1.2,filename,filename);
                if typelist{c} ~= "cud"
                    fprintf(fileID,'gdal_contour -b 1 -a ELEV -i 1.0 -f "ESRI Shapefile" %s.tif %s.shp\n',filename,filename);
                else
                    fprintf(fileID,'gdal_contour -b 1 -a ELEV -i 0.1 -f "ESRI Shapefile" -fl 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0 %s.tif %s.shp\n',filename,filename);
                end
                fclose(fileID);

                % Create bash
                fprintf(fileID0,'sh ./%s.sh\n',filename);         
            end
        end
    end    
end
fclose(fileID0);
fclose(fileID1);

