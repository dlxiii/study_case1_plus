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

ncfile.name = '../otp/d_tokyobay_0001.nc';
fprintf(['NC file at:',ncfile.name,'\n']);
% ncfile.info = ncdisp(ncfile.name);

% 2014-07-01, 2014-07-02, 2014-10-01, 2015-06-01
list_jj = [...
    (31+28+31+30+31+30)*24+1,...
    (31+28+31+30+31+30+1)*24+1,...
    (31+28+31+30+31+30+31+31+30)*24+1,...
    (31+28+31+30+31+30+31+31+30+31+30+31+31+28+31+30+31)*24+1];

% jj = (31+28+31+30+31+30+31+31)*24+1;           % From Sep 2014
% ti = 1;           % Time interval 6 hours.
% start = jj;       % 0*24+1;
% extent = Inf;     % number or 'Inf'
% extent = (1)*24+1; % From Sep to 
% only for test
%{
jj = (0)*24+1;           % From 1/1/2014
ti = 1;           % Time interval 6 hours.
start = jj;       % 0*24+1;
% extent = Inf;     % number or 'Inf'
extent = (31+28+31)*24+1; % 10 days 
%}
filename = 'd_ncfile_dates.mat';

%=================================================================================
% variable   long name                         units             dimensions
%=================================================================================
% x:         nodal x-coordinate                meters           [node]
% y:         nodal y-coordinate                meters           [node]
% lon:	     nodal longitude                   degrees_east     [node]
% lat:	     nodal latitude                    degrees_north    [node]
% xc:        zonal x-coordinate                meters           [nele]
% yc:        zonal y-coordinate                meters           [nele]
% lonc:	     zonal longitude                   degrees_east     [nele]
% latc:	     zonal latitude                    degrees_north    [nele]
% siglay:    Sigma Layers                      -                [node,siglay]
% nv:        nodes surrounding element         -                [nele,three]
% Times:     time                              -                [time]
% zeta:      Water Surface Elevation           meters           [node,time]
% ua:        Vertically Averaged x-velocity    meters s-1       [nele,time]
% va:        Vertically Averaged y-velocity    meters s-1       [nele,time]
% temp:      temperature                       degrees_C        [node,siglay,time]
% salinity:  salinity                          1e-3             [node,siglay,time]
% DYE:       passive tracer concentration      -                [node,siglay,time]
% DYE_AGE:   passive tracer concentration age  sec              [node,siglay,time]
%=================================================================================
    
vartoread = {'x','y','lon','lat','h','nv','siglay'};%'lonc','latc'
vartoread1d = {'time','Times'};ncfile.time = [];ncfile.Times = [];
%vartoread2d = {'zeta'};ncfile.zeta = [];% 'ua','va'
vartoread3d = {'DYE','DYE_AGE'};ncfile.DYE = [];ncfile.DYE_AGE = [];ncfile.age = [];
vartoread3dn = {'DYE','DYE_AGE','age'};
for i = 1:length(vartoread)
    ncfile.(vartoread{i}) = ncread(ncfile.name,vartoread{i});
    ncfile.(vartoread{i}) = double(ncfile.(vartoread{i}));
    fprintf(['Read 0d var ',vartoread{i},'.\n']);
end
ncfile.xy           = [ncfile.x, ncfile.y];
ncfile.lonlat       = [ncfile.lon, ncfile.lat];
ncfile.tri_xy       = triangulation(ncfile.nv,ncfile.xy);
ncfile.tri_lonlat   = triangulation(ncfile.nv,ncfile.lonlat);
ncfile.tri          = ncfile.tri_xy.ConnectivityList;
ncfile.tri(:,[2 3]) = ncfile.tri(:,[3 2]);
    
for jj = 1:length(list_jj)
    start = list_jj(jj);
    extent = (1)*24+0;
    if exist('vartoread1d','var') == 1
        % 1d time dimension
        ncfile_temp.time = ncread(ncfile.name,'time',[start],[extent]);
        ncfile_temp.Times = ncread(ncfile.name,'Times',[1, start],[Inf, extent]);
        % Minor change array of ncfile.Times
        ncfile_temp.Times = ncfile_temp.Times';
        fprintf(['Read 1d var time and Times.\n']);
    end
    if exist('vartoread2d','var') == 1
        % 2d variables
        for i = 1:length(vartoread2d)
            ncfile_temp.(vartoread2d{i}) = ncread(ncfile.name,vartoread2d{i},[1, start],[Inf, extent]);
            fprintf(['Read 2d var ',vartoread2d{i},'.\n']);
        end
    end
    if exist('vartoread3d','var') == 1
        % 3d variables
        for i = 1:length(vartoread3d)
            ncfile_temp.(vartoread3d{i}) = ncread(ncfile.name,vartoread3d{i},[1, 1, start],[Inf, Inf, extent]);
            fprintf(['Read 3d var ',vartoread3d{i},'.\n']);
        end
        if ismember('DYE',vartoread3d) && ismember('DYE_AGE',vartoread3d)
            % water_mask = squeeze(ncfile.DYE<=1E-6);
            % water_age = squeeze(ncfile.DYE_AGE./ncfile.DYE);
            water_mask = ncfile_temp.DYE<=1E-6;
            water_age = ncfile_temp.DYE_AGE./ncfile_temp.DYE;
            water_age(water_mask)=nan;
            water_age=water_age/24/60;
            ncfile_temp.age=water_age;
            clear water_*
        end
    end
    % combine ncfile
    if exist('vartoread1d','var') == 1
        ncfile.time = cat(1,ncfile.time,ncfile_temp.time);
        ncfile.Times = cat(1,ncfile.Times,ncfile_temp.Times);
        fprintf(['Combine 1d var time and Times.\n']);
    end
    if exist('vartoread2d','var') == 1
        for i = 1:length(vartoread2d)
            ncfile.(vartoread2d{i}) = cat(2,ncfile.(vartoread2d{i}),ncfile_temp.(vartoread2d{i}));
            fprintf(['Combine 2d var ',vartoread2d{i},'.\n']);
        end
    end
    if exist('vartoread3d','var') == 1
        for i = 1:length(vartoread3dn)
            ncfile.(vartoread3dn{i}) = cat(3,ncfile.(vartoread3dn{i}),ncfile_temp.(vartoread3dn{i}));
            fprintf(['Combine 3d var ',vartoread3dn{i},'.\n']);
        end
    end
end
% clear ncfile.temp;
fprintf(['NC file reading finished.\n']);
save(filename,'ncfile','-v7.3','-nocompression');

%%
yidx = {'14','14','14','15'};
midx = {'07','07','10','06'};
didx = {'01','02','01','01'};

for id = 1:length(yidx)
    timetoplot = {['age',yidx{id},'_',midx{id},'_',didx{id}]};
    TD.Times = ['20',yidx{id},'_',midx{id},'_',didx{id}];
    % k1 = find(ncfile.time == mjuliandate(str2num(['20',yidx{id}]),str2num(midx{id}),01));
    k1 = find(ncfile.time == greg2mjulian(str2num(['20',yidx{id}]),str2num(midx{id}),str2num(didx{id}),0,0,0));
    k2 = k1 + 23;
    TD.(['age',yidx{id},'_',midx{id},'_',didx{id}]) = mean(ncfile.age(:,:,k1:k2),3,'omitnan');
end

TD.lon = ncfile.lon;
TD.lat = ncfile.lat;
TD.nv = ncfile.nv;
TD.siglay = ncfile.siglay;
fprintf(['Water age extracting finished.\n']);
save('d_ncfile_date_TD.mat','TD','-v7.3','-nocompression');