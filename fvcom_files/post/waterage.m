clear all;
clearvars; 
clc;

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

folderpath = {...
    'meiji','present',...
    };
typepath = {...
    'u','d',...
    'r'};
month = {'age14_09','age14_10','age14_11','age14_12',...
    'age15_01','age15_02','age15_03','age15_04','age15_05','age15_06',...
    'age15_07','age15_08'};
mcode = {'m09','m10','m11','m12',...
    'm01','m02','m03','m04','m05','m06',...
    'm07','m08'};

%% Extracting wa.mat
wa = [];
for f = 1:length(folderpath)
    for t = 1:length(typepath)
        load(fullfile(['/Users/yulong/GitHub/study_case1_plus/fvcom_files/',...
            folderpath{f},'/pst/',typepath{t},'_ncfile_TD.mat']));
        if t == 1
            wa.(folderpath{f}).lon = TD.lon;
            wa.(folderpath{f}).lat = TD.lat;
            wa.(folderpath{f}).nv = TD.nv;
            wa.(folderpath{f}).siglay = TD.siglay;
            for m = 1:length(mcode)
                wa.(folderpath{f}).cu.(mcode{m}) = TD.(month{m});
            end
        else
            for m = 1:length(mcode)
                wa.(folderpath{f}).(['c',typepath{t}]).(mcode{m}) = TD.(month{m});
            end
        end
        clear TD;
    end
end
save('wa.mat','wa','-v7.3','-nocompression');

%% Interpolating wa.mat
mwa = [];
csv_resol = 500;
layerlist = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20];
month = {'m09','m10','m11','m12',...
    'm01','m02','m03','m04','m05','m06',...
    'm07','m08'};
typelist = {'cu','cd','cr'};
for f = 1:length(folderpath)
    for c = 1:length(typelist)
        for l = 1:length(layerlist)
            layer = layerlist(l);
            for m = 1:length(month)
                data1 = double(wa.(folderpath{f}).(typelist{c}).(month{m})(:,layer));
                data1 = filloutliers(data1,'nearest','mean');
                data_temp.intp = scatteredInterpolant(...
                    wa.(folderpath{f}).lon,...
                    wa.(folderpath{f}).lat,...
                    data1,...
                    'natural');
                data_temp.lonint = (139.14:(csv_resol/111000):140.39)';
                data_temp.latint = (34.85:(csv_resol/111000):35.70)';
                data_temp.ageint = data_temp.intp({data_temp.lonint,data_temp.latint});
                data = data_temp.ageint;
                data = filloutliers(data,'nearest','mean');
                mwa.(folderpath{f}).(typelist{c}).(month{m})(:,:,layer) = data;
                mwa.lon = data_temp.lonint;
                mwa.lat = data_temp.latint;
            end
        end
    end
end
% calculate ratio of up/down age
for f = 1:length(folderpath)
    for m = 1:length(month)
        mwa.(folderpath{f}).cud.(month{m})=...
            mwa.(folderpath{f}).cu.(month{m})./...
            mwa.(folderpath{f}).cd.(month{m});
    end
end

% calculate annual age
typelist = {'cu','cd','cr','cud'};
for f = 1:length(folderpath)
    for c = 1:length(typelist)
        for l = 1:length(layerlist)
            layer = layerlist(l);
            mwa.(folderpath{f}).(typelist{c}).m00 = 0;
            for m = 1:length(month)
                % data = mwa.(folderpath{f}).(typelist{c}).(month{m});(:,:,layer);
                mwa.(folderpath{f}).(typelist{c}).m00 = ...
                    mwa.(folderpath{f}).(typelist{c}).m00 + ...
                    mwa.(folderpath{f}).(typelist{c}).(month{m});
            end
            mwa.(folderpath{f}).(typelist{c}).m00 = ...
                mwa.(folderpath{f}).(typelist{c}).m00 / 12;
        end
    end
end
% calculate annual vertical mean age
typelist = {'cu','cd','cr','cud'};
for f = 1:length(folderpath)
    for c = 1:length(typelist)
        mwa.(folderpath{f}).(typelist{c}).m00_va = 0;
        for m = 1:length(month)
            % data = mwa.(folderpath{f}).(typelist{c}).(month{m});(:,:,layer);
            mwa.(folderpath{f}).(typelist{c}).m00_va = ...
                mean(mwa.(folderpath{f}).(typelist{c}).m00,3);
        end
    end
end
save('wa_mesh.mat','mwa','-v7.3','-nocompression');
%% Calculating wa_dif.mat

for f = 1:length(folderpath)
    for c = 1:length(typelist)
        for l = 1:length(layerlist)
            layer = layerlist(l);
            for m = 1:length(month)
                wa_dif.(typelist{c}).(month{m})(:,:,layer) = ...
                    mwa.present.(typelist{c}).(month{m})(:,:,layer) - ...
                    mwa.meiji.(typelist{c}).(month{m})(:,:,layer);
                wa_dif.lon = mwa.lon;
                wa_dif.lat = mwa.lat;
            end
        end
    end
end
save('wa_dif.mat','wa_dif','-v7.3','-nocompression');                
