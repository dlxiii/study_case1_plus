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
    'u','d'};
dcode = {...
    'age14_07_01',...
    'age14_07_02',...
    'age14_10_01',...
    'age15_06_01',...
    };

%% Extracting wad.mat
wad = [];
for f = 1:length(folderpath)
    for t = 1:length(typepath)
        load(fullfile(['/Users/yulong/GitHub/study_case1_plus/fvcom_files/',...
            folderpath{f},'/pst/',typepath{t},'_ncfile_date_TD.mat']));
        if t == 1
            wad.(folderpath{f}).lon = TD.lon;
            wad.(folderpath{f}).lat = TD.lat;
            wad.(folderpath{f}).nv = TD.nv;
            wad.(folderpath{f}).siglay = TD.siglay;
            for d = 1:length(dcode)
                wad.(folderpath{f}).(['c',typepath{t}]).(dcode{d}) = TD.(dcode{d});
            end
        else
            for d = 1:length(dcode)
                wad.(folderpath{f}).(['c',typepath{t}]).(dcode{d}) = TD.(dcode{d});
            end
        end
        clear TD;
    end
end

% calculate ratio of up/down age
for f = 1:length(folderpath)
    for m = 1:length(dcode)
        wad.(folderpath{f}).cud.(dcode{m})=...
            wad.(folderpath{f}).cu.(dcode{m})./...
            wad.(folderpath{f}).cd.(dcode{m});
    end
end
save('wad.mat','wad','-v7.3','-nocompression');

%% Interpolating wad.mat
wadi = [];
csv_resol = 500;
layerlist = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20];
dcode = {...
    'age14_07_01',...
    'age14_07_02',...
    'age14_10_01',...
    'age15_06_01',...
    };
typelist = {'cu','cd','cud'};
for f = 1:length(folderpath)
    for c = 1:length(typelist)
        for l = 1:length(layerlist)
            layer = layerlist(l);
            for m = 1:length(dcode)
                data1 = double(wad.(folderpath{f}).(typelist{c}).(dcode{m})(:,layer));
                data1 = filloutliers(data1,'nearest','mean');
                data_temp.intp = scatteredInterpolant(...
                    wad.(folderpath{f}).lon,...
                    wad.(folderpath{f}).lat,...
                    data1,...
                    'natural');
                data_temp.lonint = (139.14:(csv_resol/111000):140.39)';
                data_temp.latint = (34.85:(csv_resol/111000):35.70)';
                data_temp.ageint = data_temp.intp({data_temp.lonint,data_temp.latint});
                data = data_temp.ageint;
                data = filloutliers(data,'nearest','mean');
                wadi.(folderpath{f}).(typelist{c}).(dcode{m})(:,:,layer) = data;
                wadi.lon = data_temp.lonint;
                wadi.lat = data_temp.latint;
            end
        end
    end
end
save('wadi.mat','wadi','-v7.3','-nocompression');