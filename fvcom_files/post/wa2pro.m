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
td = load("./wa_mesh.mat");
mwa = td.mwa;
clear td;
if exist('../../wa_files', 'dir')~=7
    mkdir('../../wa_files')
end

%% cross sectional profiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
folderpath = {'meiji','present'};
typelist = {'cu','cd','cud','cr'};
bndlist = {'../../gis_files/lines/bnd_inn.shp',...
    '../../gis_files/lines/bnd_out_inn.shp',...
    '../../gis_files/lines/bnd_out.shp',...
    '../../gis_files/lines/crs_ns.shp',...
    '../../gis_files/lines/crs_we1.shp',...
    '../../gis_files/lines/crs_we2.shp',...
    '../../gis_files/lines/crs_we3.shp',...
    '../../gis_files/lines/river_nakagawa.shp',...
    '../../gis_files/lines/river_sumidagawa.shp',...
    '../../gis_files/lines/river_tamagawa.shp'};
layerlist = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20];
month = {'m09','m10','m11','m12',...
    'm01','m02','m03','m04','m05','m06',...
    'm07','m08'};
mmean = {'m00'};
csv_resol = 100;

wa_pr = {};
for f = 1:length(folderpath) 
    % interpolation of topo data
    % f=1;
    % ncdisp('../../gis_files/present/bathymetry/present_elevation.nc')
    % ncdisp('../../gis_files/meiji/bathymetry/meiji_elevation.tif
    topodata = ['../../gis_files/',folderpath{f},'/bathymetry/',folderpath{f},'_elevation_cut.nc'];
    % ncdisp(topodata);
    dz = ncread(topodata,'Band1');
    dx = ncread(topodata,'lon');
    dy = ncread(topodata,'lat');
    [DY,DX] = meshgrid(dy,dx);
    data_topo.intp = scatteredInterpolant(...
        reshape(DX,[numel(DX),1]),...
        reshape(DY,[numel(DY),1]),...
        reshape(dz,[numel(dz),1]),...
        'natural');
    clear dx dy dz DX DY;
    topo = {};
    for b = 1:length(bndlist)
        [x,y,z] = valOnLine(csv_resol,data_topo,bndlist{b});
        topo{end + 1} = [x;y;z]';
        clear x y z;
    end
    value = {};
    for c = 1:length(typelist)
        data = {};
        for m = 1:length(mmean)
            for l = 1:length(layerlist)
                layer = layerlist(l);
                % interpolation of simulation data
                % f=1;c=1;l=1;layer=layerlist(l);m=1;b=1;
                Z = mwa.(folderpath{f}).(typelist{c}).(mmean{m})(:,:,layer);
                [Y,X] = meshgrid(mwa.lat,mwa.lon);
                data_val.intp = scatteredInterpolant(...
                    reshape(X,[numel(X),1]),...
                    reshape(Y,[numel(Y),1]),...
                    reshape(Z,[numel(Z),1]),...
                    'natural');
                clear Y X Z;
                for b = 1:length(bndlist)
                    [~,~,z] = valOnLine(csv_resol,data_val,bndlist{b});
                    data{m,b}(l,:) = z;
                    clear z;
                end
            end
        end
        value{c+1} = data;
    end
    value{1}=topo;
    clear data topo data_topo data_val;
    wa_pr{f}=value;
    clear value;
end
save('wa_pr.mat','wa_pr','-v7.3','-nocompression'); 