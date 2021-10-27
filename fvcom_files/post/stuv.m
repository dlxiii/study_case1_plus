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
    'present','meiji'...
    };
typepath = {...
    ''};
month = {'14_09','14_10','14_11','14_12',...
    '15_01','15_02','15_03','15_04','15_05','15_06',...
    '15_07','15_08'};
mcode = {'m09','m10','m11','m12',...
    'm01','m02','m03','m04','m05','m06',...
    'm07','m08'};
verb = {'temp','salinity','rho1','u','v'};

%% Extracting mstrhouv.mat
strhouv = [];
for f = 1:length(folderpath)
    load(fullfile(['/Users/yulong/GitHub/study_case1_plus/fvcom_files/',...
        folderpath{f},'/pst/ncfile_stuv.mat']));
    strhouv.(folderpath{f}).lon = TD.lon;
    strhouv.(folderpath{f}).lat = TD.lat;
    strhouv.(folderpath{f}).lonc = TD.lonc;
    strhouv.(folderpath{f}).latc = TD.latc;
    % strhouv.(folderpath{f}).nv = TD.nv;
    % strhouv.(folderpath{f}).siglay = TD.siglay;
    for v = 1:length(verb)
        for m = 1:length(mcode)
            strhouv.(folderpath{f}).(verb{v}).(mcode{m}) = TD.([verb{v},month{m}]);
        end
    end
end
clear TD;
save('strhouv.mat','strhouv','-v7.3','-nocompression');

%% Interpolating wa.mat
mstrhouv = [];
csv_resol = 500;
layerlist = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20];
month = {'m09','m10','m11','m12',...
    'm01','m02','m03','m04','m05','m06',...
    'm07','m08'};
for f = 1:length(folderpath)
    for v = 1:length(verb)
        for l = 1:length(layerlist)
            layer = layerlist(l);
            for m = 1:length(month)
                data1 = double(strhouv.(folderpath{f}).(verb{v}).(month{m})(:,layer));
                data1 = filloutliers(data1,'nearest','mean');
                if strcmpi(verb{v}, 'u') || strcmpi(verb{v}, 'v')
                    data_temp.intp = scatteredInterpolant(...
                        strhouv.(folderpath{f}).lonc,...
                        strhouv.(folderpath{f}).latc,...
                        data1,...
                        'natural');
                else
                    data_temp.intp = scatteredInterpolant(...
                        strhouv.(folderpath{f}).lon,...
                        strhouv.(folderpath{f}).lat,...
                        data1,...
                        'natural');
                end
                data_temp.lonint = (139.14:(csv_resol/111000):140.39)';
                data_temp.latint = (34.85:(csv_resol/111000):35.70)';
                data_temp.ageint = data_temp.intp({data_temp.lonint,data_temp.latint});
                data = data_temp.ageint;
                data = filloutliers(data,'nearest','mean');
                mstrhouv.(folderpath{f}).(verb{v}).(month{m})(:,:,layer) = data;
                mstrhouv.lon = data_temp.lonint;
                mstrhouv.lat = data_temp.latint;
            end
        end
    end
end

% calculate annual value
for f = 1:length(folderpath)
    for v = 1:length(verb)
        for l = 1:length(layerlist)
            layer = layerlist(l);
            mstrhouv.(folderpath{f}).(verb{v}).m00 = 0;
            for m = 1:length(month)
                mstrhouv.(folderpath{f}).(verb{v}).m00 = ...
                    mstrhouv.(folderpath{f}).(verb{v}).m00 + ...
                    mstrhouv.(folderpath{f}).(verb{v}).(month{m});
            end
            mstrhouv.(folderpath{f}).(verb{v}).m00 = ...
                mstrhouv.(folderpath{f}).(verb{v}).m00 / 12;
        end
    end
end

% calculate annual vertical mean age
for f = 1:length(folderpath)
    for v = 1:length(verb)
        mstrhouv.(folderpath{f}).(verb{v}).m00_va = ...
            mean(mstrhouv.(folderpath{f}).(verb{v}).m00,3);
    end
end
save('strhouv_mesh.mat','mstrhouv','-v7.3','-nocompression');
%% Calculating strhouv_dif.mat
for f = 1:length(folderpath)
    for v = 1:length(verb)
        for m = 1:length(month)
            mstrhouv_dif.(verb{v}).(month{m}) = ...
                mstrhouv.present.(verb{v}).(month{m}) - ...
                mstrhouv.meiji.(verb{v}).(month{m});
        end
    end
end
mstrhouv_dif.lon = mstrhouv.lon;
mstrhouv_dif.lat = mstrhouv.lat;

% calculate annual age dif
for v = 1:length(verb)
    mstrhouv_dif.(verb{v}).m00 = 0;
    for m = 1:length(month)
        mstrhouv_dif.(verb{v}).m00 = ...
            mstrhouv_dif.(verb{v}).m00 + ...
            mstrhouv_dif.(verb{v}).(month{m});
    end
    mstrhouv_dif.(verb{v}).m00 = ...
        mstrhouv_dif.(verb{v}).m00 / 12;
end

% calculate annual vertical mean age dif
for v = 1:length(verb)
    mstrhouv_dif.(verb{v}).m00_va = ...
        mean(mstrhouv_dif.(verb{v}).m00,3);
end

% calculate annual value dif rate
for v = 1:length(verb)
    mstrhouv_dif.(['d',verb{v}]).m00 = ...
        mstrhouv_dif.(verb{v}).m00 ./ ...
        mstrhouv.meiji.(verb{v}).m00;
end

save('mstrhouv_dif.mat','mstrhouv_dif','-v7.3','-nocompression');                
