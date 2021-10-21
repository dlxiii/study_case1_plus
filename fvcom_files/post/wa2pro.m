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

%%
% plot river age, consider layer, age type and river name
%       type     u    crs  layer
% wa_pr{1, 2}{1, 2}{1, 4}(1,:)
%       meij     u     i
%       pres     d    io
%              cud     o
%                r    ns
%                    ws1
%                    ws2
%                    ws3
%                     r1
%                     r2
%                     r3
%% plot_cs_ns_u.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 2}{1, 4}(1,:); wa_pr{1, 2}{1, 2}{1, 4}(1,:);...
    wa_pr{1, 1}{1, 2}{1, 4}(8,:); wa_pr{1, 2}{1, 2}{1, 4}(8,:);...
    wa_pr{1, 1}{1, 2}{1, 4}(16,:); wa_pr{1, 2}{1, 2}{1, 4}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','LineWidth',3,'Parent',axes1);
set(plot1(1),'DisplayName','M, S','LineStyle',':');
set(plot1(2),'DisplayName','P, S');
set(plot1(3),'DisplayName','M, M','LineStyle',':');
set(plot1(4),'DisplayName','P, M');
set(plot1(5),'DisplayName','M, B','LineStyle',':');
set(plot1(6),'DisplayName','P, B');
% Create ylabel
ylabel('Upstream Age (day)');
ylim([0,100]);
% Create xlabel
xlabel('Distance (km)');
xlim([0,55]);
% Create title
% title('Upstream age of NS cross section');
box(axes1,'on');
% Set the remaining axes properties
set(axes1,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(axes1,'show');
% Save png
saveas(gcf,'plot_cs_ns_u.png');

% plot_cs_ns_d.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 3}{1, 4}(1,:); wa_pr{1, 2}{1, 3}{1, 4}(1,:);...
    wa_pr{1, 1}{1, 3}{1, 4}(8,:); wa_pr{1, 2}{1, 3}{1, 4}(8,:);...
    wa_pr{1, 1}{1, 3}{1, 4}(16,:); wa_pr{1, 2}{1, 3}{1, 4}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','LineWidth',3,'Parent',axes1);
set(plot1(1),'DisplayName','M, S','LineStyle',':');
set(plot1(2),'DisplayName','P, S');
set(plot1(3),'DisplayName','M, M','LineStyle',':');
set(plot1(4),'DisplayName','P, M');
set(plot1(5),'DisplayName','M, B','LineStyle',':');
set(plot1(6),'DisplayName','P, B');
% Create ylabel
ylabel('Downstream Age (day)');
ylim([0,100]);
% Create xlabel
xlabel('Distance (km)');
xlim([0,55]);
% Create title
% title('Downstream age of NS cross section');
box(axes1,'on');
% Set the remaining axes properties
set(axes1,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(axes1,'show');
% Save png
saveas(gcf,'plot_cs_ns_d.png');

% plot_cs_ns_ud.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 4}{1, 4}(1,:); wa_pr{1, 2}{1, 4}{1, 4}(1,:);...
    wa_pr{1, 1}{1, 4}{1, 4}(8,:); wa_pr{1, 2}{1, 4}{1, 4}(8,:);...
    wa_pr{1, 1}{1, 4}{1, 4}(16,:); wa_pr{1, 2}{1, 4}{1, 4}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','LineWidth',3,'Parent',axes1);
set(plot1(1),'DisplayName','M, S','LineStyle',':');
set(plot1(2),'DisplayName','P, S');
set(plot1(3),'DisplayName','M, M','LineStyle',':');
set(plot1(4),'DisplayName','P, M');
set(plot1(5),'DisplayName','M, B','LineStyle',':');
set(plot1(6),'DisplayName','P, B');
% Create ylabel
ylabel('U/D (-)');
ylim([0,2]);
% Create xlabel
xlabel('Distance (km)');
xlim([0,55]);
% Create title
% title('U/D of NS cross section');
box(axes1,'on');
% Set the remaining axes properties
set(axes1,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(axes1,'show');
% Save png
saveas(gcf,'plot_cs_ns_ud.png');

% plot_cs_ns_r.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 5}{1, 4}(1,:); wa_pr{1, 2}{1, 5}{1, 4}(1,:);...
    wa_pr{1, 1}{1, 5}{1, 4}(8,:); wa_pr{1, 2}{1, 5}{1, 4}(8,:);...
    wa_pr{1, 1}{1, 5}{1, 4}(16,:); wa_pr{1, 2}{1, 5}{1, 4}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','LineWidth',3,'Parent',axes1);
set(plot1(1),'DisplayName','M, S','LineStyle',':');
set(plot1(2),'DisplayName','P, S');
set(plot1(3),'DisplayName','M, M','LineStyle',':');
set(plot1(4),'DisplayName','P, M');
set(plot1(5),'DisplayName','M, B','LineStyle',':');
set(plot1(6),'DisplayName','P, B');
% Create ylabel
ylabel('Renewing Age (day)');
ylim([0,100]);
% Create xlabel
xlabel('Distance (km)');
xlim([0,55]);
% Create title
% title('Renewing age of NS cross section');
box(axes1,'on');
% Set the remaining axes properties
set(axes1,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(axes1,'show');
% Save png
saveas(gcf,'plot_cs_ns_r.png');

%% plot_cs_we_u.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 2}{1, 5}(1,:); wa_pr{1, 2}{1, 2}{1, 5}(1,:);...
    wa_pr{1, 1}{1, 2}{1, 5}(8,:); wa_pr{1, 2}{1, 2}{1, 5}(8,:);...
    wa_pr{1, 1}{1, 2}{1, 5}(16,:); wa_pr{1, 2}{1, 2}{1, 5}(16,:);...
    ];
YMatrix2=[...
    wa_pr{1, 1}{1, 2}{1, 6}(1,:); wa_pr{1, 2}{1, 2}{1, 6}(1,:);...
    wa_pr{1, 1}{1, 2}{1, 6}(8,:); wa_pr{1, 2}{1, 2}{1, 6}(8,:);...
    wa_pr{1, 1}{1, 2}{1, 6}(16,:); wa_pr{1, 2}{1, 2}{1, 6}(16,:);...
    ];
YMatrix3=[...
    wa_pr{1, 1}{1, 2}{1, 7}(1,:); wa_pr{1, 2}{1, 2}{1, 7}(1,:);...
    wa_pr{1, 1}{1, 2}{1, 7}(8,:); wa_pr{1, 2}{1, 2}{1, 7}(8,:);...
    wa_pr{1, 1}{1, 2}{1, 7}(16,:); wa_pr{1, 2}{1, 2}{1, 7}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,3,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','Parent',subplot1,'LineWidth',3);
set(plot1(1),'LineStyle',':');
set(plot1(3),'LineStyle',':');
set(plot1(5),'LineStyle',':');
% Create ylabel
ylabel('Upstream Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE1');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 17]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot1,[0 100]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,3,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix2)]/10,YMatrix2','Parent',subplot2,'LineWidth',3);
set(plot2(1),'LineStyle',':');
set(plot2(3),'LineStyle',':');
set(plot2(5),'LineStyle',':');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE2');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot2,[0 100]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot3 = subplot(1,3,3,'Parent',figure1);
hold(subplot3,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([1:length(YMatrix3)]/10,YMatrix3','Parent',subplot3,'LineWidth',3);
set(plot3(1),'DisplayName','M, S','LineStyle',':');
set(plot3(2),'DisplayName','P, S');
set(plot3(3),'DisplayName','M, M','LineStyle',':');
set(plot3(4),'DisplayName','P, M');
set(plot3(5),'DisplayName','M, B','LineStyle',':');
set(plot3(6),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE3');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot3,[0 100]);
box(subplot3,'on');
% Set the remaining axes properties
set(subplot3,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot3,'show');
linkaxes([subplot1, subplot2, subplot3], 'y');
saveas(gcf,'plot_cs_we_u.png');

% plot_cs_we_d.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 3}{1, 5}(1,:); wa_pr{1, 2}{1, 3}{1, 5}(1,:);...
    wa_pr{1, 1}{1, 3}{1, 5}(8,:); wa_pr{1, 2}{1, 3}{1, 5}(8,:);...
    wa_pr{1, 1}{1, 3}{1, 5}(16,:); wa_pr{1, 2}{1, 3}{1, 5}(16,:);...
    ];
YMatrix2=[...
    wa_pr{1, 1}{1, 3}{1, 6}(1,:); wa_pr{1, 2}{1, 3}{1, 6}(1,:);...
    wa_pr{1, 1}{1, 3}{1, 6}(8,:); wa_pr{1, 2}{1, 3}{1, 6}(8,:);...
    wa_pr{1, 1}{1, 3}{1, 6}(16,:); wa_pr{1, 2}{1, 3}{1, 6}(16,:);...
    ];
YMatrix3=[...
    wa_pr{1, 1}{1, 3}{1, 7}(1,:); wa_pr{1, 2}{1, 3}{1, 7}(1,:);...
    wa_pr{1, 1}{1, 3}{1, 7}(8,:); wa_pr{1, 2}{1, 3}{1, 7}(8,:);...
    wa_pr{1, 1}{1, 3}{1, 7}(16,:); wa_pr{1, 2}{1, 3}{1, 7}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,3,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','Parent',subplot1,'LineWidth',3);
set(plot1(1),'LineStyle',':');
set(plot1(3),'LineStyle',':');
set(plot1(5),'LineStyle',':');
% Create ylabel
ylabel('Downstream Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE1');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 17]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot1,[0 100]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,3,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix2)]/10,YMatrix2','Parent',subplot2,'LineWidth',3);
set(plot2(1),'LineStyle',':');
set(plot2(3),'LineStyle',':');
set(plot2(5),'LineStyle',':');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE2');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot2,[0 100]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot3 = subplot(1,3,3,'Parent',figure1);
hold(subplot3,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([1:length(YMatrix3)]/10,YMatrix3','Parent',subplot3,'LineWidth',3);
set(plot3(1),'DisplayName','M, S','LineStyle',':');
set(plot3(2),'DisplayName','P, S');
set(plot3(3),'DisplayName','M, M','LineStyle',':');
set(plot3(4),'DisplayName','P, M');
set(plot3(5),'DisplayName','M, B','LineStyle',':');
set(plot3(6),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE3');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot3,[0 100]);
box(subplot3,'on');
% Set the remaining axes properties
set(subplot3,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot3,'show');
linkaxes([subplot1, subplot2, subplot3], 'y');
saveas(gcf,'plot_cs_we_d.png');

% plot_cs_we_ud.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 4}{1, 5}(1,:); wa_pr{1, 2}{1, 4}{1, 5}(1,:);...
    wa_pr{1, 1}{1, 4}{1, 5}(8,:); wa_pr{1, 2}{1, 4}{1, 5}(8,:);...
    wa_pr{1, 1}{1, 4}{1, 5}(16,:); wa_pr{1, 2}{1, 4}{1, 5}(16,:);...
    ];
YMatrix2=[...
    wa_pr{1, 1}{1, 4}{1, 6}(1,:); wa_pr{1, 2}{1, 4}{1, 6}(1,:);...
    wa_pr{1, 1}{1, 4}{1, 6}(8,:); wa_pr{1, 2}{1, 4}{1, 6}(8,:);...
    wa_pr{1, 1}{1, 4}{1, 6}(16,:); wa_pr{1, 2}{1, 4}{1, 6}(16,:);...
    ];
YMatrix3=[...
    wa_pr{1, 1}{1, 4}{1, 7}(1,:); wa_pr{1, 2}{1, 4}{1, 7}(1,:);...
    wa_pr{1, 1}{1, 4}{1, 7}(8,:); wa_pr{1, 2}{1, 4}{1, 7}(8,:);...
    wa_pr{1, 1}{1, 4}{1, 7}(16,:); wa_pr{1, 2}{1, 4}{1, 7}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,3,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','Parent',subplot1,'LineWidth',3);
set(plot1(1),'LineStyle',':');
set(plot1(3),'LineStyle',':');
set(plot1(5),'LineStyle',':');
% Create ylabel
ylabel('U/D (-)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE1');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 17]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot1,[0 3]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,3,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix2)]/10,YMatrix2','Parent',subplot2,'LineWidth',3);
set(plot2(1),'LineStyle',':');
set(plot2(3),'LineStyle',':');
set(plot2(5),'LineStyle',':');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE2');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot2,[0 3]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot3 = subplot(1,3,3,'Parent',figure1);
hold(subplot3,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([1:length(YMatrix3)]/10,YMatrix3','Parent',subplot3,'LineWidth',3);
set(plot3(1),'DisplayName','M, S','LineStyle',':');
set(plot3(2),'DisplayName','P, S');
set(plot3(3),'DisplayName','M, M','LineStyle',':');
set(plot3(4),'DisplayName','P, M');
set(plot3(5),'DisplayName','M, B','LineStyle',':');
set(plot3(6),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE3');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot3,[0 3]);
box(subplot3,'on');
% Set the remaining axes properties
set(subplot3,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot3,'show');
linkaxes([subplot1, subplot2, subplot3], 'y');
saveas(gcf,'plot_cs_we_ud.png');

% plot_cs_ws_r.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 5}{1, 5}(1,:); wa_pr{1, 2}{1, 5}{1, 5}(1,:);...
    wa_pr{1, 1}{1, 5}{1, 5}(8,:); wa_pr{1, 2}{1, 5}{1, 5}(8,:);...
    wa_pr{1, 1}{1, 5}{1, 5}(16,:); wa_pr{1, 2}{1, 5}{1, 5}(16,:);...
    ];
YMatrix2=[...
    wa_pr{1, 1}{1, 5}{1, 6}(1,:); wa_pr{1, 2}{1, 5}{1, 6}(1,:);...
    wa_pr{1, 1}{1, 5}{1, 6}(8,:); wa_pr{1, 2}{1, 5}{1, 6}(8,:);...
    wa_pr{1, 1}{1, 5}{1, 6}(16,:); wa_pr{1, 2}{1, 5}{1, 6}(16,:);...
    ];
YMatrix3=[...
    wa_pr{1, 1}{1, 5}{1, 7}(1,:); wa_pr{1, 2}{1, 5}{1, 7}(1,:);...
    wa_pr{1, 1}{1, 5}{1, 7}(8,:); wa_pr{1, 2}{1, 5}{1, 7}(8,:);...
    wa_pr{1, 1}{1, 5}{1, 7}(16,:); wa_pr{1, 2}{1, 5}{1, 7}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,3,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','Parent',subplot1,'LineWidth',3);
set(plot1(1),'LineStyle',':');
set(plot1(3),'LineStyle',':');
set(plot1(5),'LineStyle',':');
% Create ylabel
ylabel('Renewing Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE1');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 17]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot1,[0 100]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,3,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix2)]/10,YMatrix2','Parent',subplot2,'LineWidth',3);
set(plot2(1),'LineStyle',':');
set(plot2(3),'LineStyle',':');
set(plot2(5),'LineStyle',':');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE2');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot2,[0 100]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot3 = subplot(1,3,3,'Parent',figure1);
hold(subplot3,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([1:length(YMatrix3)]/10,YMatrix3','Parent',subplot3,'LineWidth',3);
set(plot3(1),'DisplayName','M, S','LineStyle',':');
set(plot3(2),'DisplayName','P, S');
set(plot3(3),'DisplayName','M, M','LineStyle',':');
set(plot3(4),'DisplayName','P, M');
set(plot3(5),'DisplayName','M, B','LineStyle',':');
set(plot3(6),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE3');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot3,[0 100]);
box(subplot3,'on');
% Set the remaining axes properties
set(subplot3,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot3,'show');
linkaxes([subplot1, subplot2, subplot3], 'y');
saveas(gcf,'plot_cs_we_r.png');

%% plot_cs_rv_u.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 2}{1, 8}(1,:); wa_pr{1, 2}{1, 2}{1, 8}(1,:);...
    wa_pr{1, 1}{1, 2}{1, 8}(8,:); wa_pr{1, 2}{1, 2}{1, 8}(8,:);...
    wa_pr{1, 1}{1, 2}{1, 8}(16,:); wa_pr{1, 2}{1, 2}{1, 8}(16,:);...
    ];
YMatrix2=[...
    wa_pr{1, 1}{1, 2}{1, 9}(1,:); wa_pr{1, 2}{1, 2}{1, 9}(1,:);...
    wa_pr{1, 1}{1, 2}{1, 9}(8,:); wa_pr{1, 2}{1, 2}{1, 9}(8,:);...
    wa_pr{1, 1}{1, 2}{1, 9}(16,:); wa_pr{1, 2}{1, 2}{1, 9}(16,:);...
    ];
YMatrix3=[...
    wa_pr{1, 1}{1, 2}{1, 10}(1,:); wa_pr{1, 2}{1, 2}{1, 10}(1,:);...
    wa_pr{1, 1}{1, 2}{1, 10}(8,:); wa_pr{1, 2}{1, 2}{1, 10}(8,:);...
    wa_pr{1, 1}{1, 2}{1, 10}(16,:); wa_pr{1, 2}{1, 2}{1, 10}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,3,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','Parent',subplot1,'LineWidth',3);
set(plot1(1),'LineStyle',':');
set(plot1(3),'LineStyle',':');
set(plot1(5),'LineStyle',':');
% Create ylabel
ylabel('Upstream Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('NAR');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 10]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot1,[0 100]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,3,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix2)]/10,YMatrix2','Parent',subplot2,'LineWidth',3);
set(plot2(1),'LineStyle',':');
set(plot2(3),'LineStyle',':');
set(plot2(5),'LineStyle',':');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('SUR');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot2,[0 10]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot2,[0 100]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot3 = subplot(1,3,3,'Parent',figure1);
hold(subplot3,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([1:length(YMatrix3)]/10,YMatrix3','Parent',subplot3,'LineWidth',3);
set(plot3(1),'DisplayName','M, S','LineStyle',':');
set(plot3(2),'DisplayName','P, S');
set(plot3(3),'DisplayName','M, M','LineStyle',':');
set(plot3(4),'DisplayName','P, M');
set(plot3(5),'DisplayName','M, B','LineStyle',':');
set(plot3(6),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('TAR');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot3,[0 10]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot3,[0 100]);
box(subplot3,'on');
% Set the remaining axes properties
set(subplot3,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot3,'show');
linkaxes([subplot1, subplot2, subplot3], 'y');
saveas(gcf,'plot_cs_rv_u.png');

% plot_cs_rv_d.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 3}{1, 8}(1,:); wa_pr{1, 2}{1, 3}{1, 8}(1,:);...
    wa_pr{1, 1}{1, 3}{1, 8}(8,:); wa_pr{1, 2}{1, 3}{1, 8}(8,:);...
    wa_pr{1, 1}{1, 3}{1, 8}(16,:); wa_pr{1, 2}{1, 3}{1, 8}(16,:);...
    ];
YMatrix2=[...
    wa_pr{1, 1}{1, 3}{1, 9}(1,:); wa_pr{1, 2}{1, 3}{1, 9}(1,:);...
    wa_pr{1, 1}{1, 3}{1, 9}(8,:); wa_pr{1, 2}{1, 3}{1, 9}(8,:);...
    wa_pr{1, 1}{1, 3}{1, 9}(16,:); wa_pr{1, 2}{1, 3}{1, 9}(16,:);...
    ];
YMatrix3=[...
    wa_pr{1, 1}{1, 3}{1, 10}(1,:); wa_pr{1, 2}{1, 3}{1, 10}(1,:);...
    wa_pr{1, 1}{1, 3}{1, 10}(8,:); wa_pr{1, 2}{1, 3}{1, 10}(8,:);...
    wa_pr{1, 1}{1, 3}{1, 10}(16,:); wa_pr{1, 2}{1, 3}{1, 10}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,3,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','Parent',subplot1,'LineWidth',3);
set(plot1(1),'LineStyle',':');
set(plot1(3),'LineStyle',':');
set(plot1(5),'LineStyle',':');
% Create ylabel
ylabel('Downstream Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('NAR');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 10]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot1,[0 100]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,3,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix2)]/10,YMatrix2','Parent',subplot2,'LineWidth',3);
set(plot2(1),'LineStyle',':');
set(plot2(3),'LineStyle',':');
set(plot2(5),'LineStyle',':');
% Create xlabel
xlabel('Distance (km)');
xlim(subplot2,[0 10]);
% Create title
title('SUR');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot2,[0 100]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot3 = subplot(1,3,3,'Parent',figure1);
hold(subplot3,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([1:length(YMatrix3)]/10,YMatrix3','Parent',subplot3,'LineWidth',3);
set(plot3(1),'DisplayName','M, S','LineStyle',':');
set(plot3(2),'DisplayName','P, S');
set(plot3(3),'DisplayName','M, M','LineStyle',':');
set(plot3(4),'DisplayName','P, M');
set(plot3(5),'DisplayName','M, B','LineStyle',':');
set(plot3(6),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
xlim(subplot3,[0 10]);
% Create title
title('TAR');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot3,[0 100]);
box(subplot3,'on');
% Set the remaining axes properties
set(subplot3,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot3,'show');
linkaxes([subplot1, subplot2, subplot3], 'y');
saveas(gcf,'plot_cs_rv_d.png');

% plot_cs_rv_ud.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 4}{1, 8}(1,:); wa_pr{1, 2}{1, 4}{1, 8}(1,:);...
    wa_pr{1, 1}{1, 4}{1, 8}(8,:); wa_pr{1, 2}{1, 4}{1, 8}(8,:);...
    wa_pr{1, 1}{1, 4}{1, 8}(16,:); wa_pr{1, 2}{1, 4}{1, 8}(16,:);...
    ];
YMatrix2=[...
    wa_pr{1, 1}{1, 4}{1, 9}(1,:); wa_pr{1, 2}{1, 4}{1, 9}(1,:);...
    wa_pr{1, 1}{1, 4}{1, 9}(8,:); wa_pr{1, 2}{1, 4}{1, 9}(8,:);...
    wa_pr{1, 1}{1, 4}{1, 9}(16,:); wa_pr{1, 2}{1, 4}{1, 9}(16,:);...
    ];
YMatrix3=[...
    wa_pr{1, 1}{1, 4}{1, 10}(1,:); wa_pr{1, 2}{1, 4}{1, 10}(1,:);...
    wa_pr{1, 1}{1, 4}{1, 10}(8,:); wa_pr{1, 2}{1, 4}{1, 10}(8,:);...
    wa_pr{1, 1}{1, 4}{1, 10}(16,:); wa_pr{1, 2}{1, 4}{1, 10}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,3,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','Parent',subplot1,'LineWidth',3);
set(plot1(1),'LineStyle',':');
set(plot1(3),'LineStyle',':');
set(plot1(5),'LineStyle',':');
% Create ylabel
ylabel('U/D (-)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('NAR');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 10]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot1,[0 2]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,3,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix2)]/10,YMatrix2','Parent',subplot2,'LineWidth',3);
set(plot2(1),'LineStyle',':');
set(plot2(3),'LineStyle',':');
set(plot2(5),'LineStyle',':');
% Create xlabel
xlabel('Distance (km)');
xlim(subplot2,[0 10]);
% Create title
title('SUR');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot2,[0 2]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot3 = subplot(1,3,3,'Parent',figure1);
hold(subplot3,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([1:length(YMatrix3)]/10,YMatrix3','Parent',subplot3,'LineWidth',3);
set(plot3(1),'DisplayName','M, S','LineStyle',':');
set(plot3(2),'DisplayName','P, S');
set(plot3(3),'DisplayName','M, M','LineStyle',':');
set(plot3(4),'DisplayName','P, M');
set(plot3(5),'DisplayName','M, B','LineStyle',':');
set(plot3(6),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
xlim(subplot3,[0 10]);
% Create title
title('TAR');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot3,[0 2]);
box(subplot3,'on');
% Set the remaining axes properties
set(subplot3,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot3,'show');
linkaxes([subplot1, subplot2, subplot3], 'y');
saveas(gcf,'plot_cs_rv_ud.png');

% plot_cs_rv_r.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 5}{1, 8}(1,:); wa_pr{1, 2}{1, 5}{1, 8}(1,:);...
    wa_pr{1, 1}{1, 5}{1, 8}(8,:); wa_pr{1, 2}{1, 5}{1, 8}(8,:);...
    wa_pr{1, 1}{1, 5}{1, 8}(16,:); wa_pr{1, 2}{1, 5}{1, 8}(16,:);...
    ];
YMatrix2=[...
    wa_pr{1, 1}{1, 5}{1, 9}(1,:); wa_pr{1, 2}{1, 5}{1, 9}(1,:);...
    wa_pr{1, 1}{1, 5}{1, 9}(8,:); wa_pr{1, 2}{1, 5}{1, 9}(8,:);...
    wa_pr{1, 1}{1, 5}{1, 9}(16,:); wa_pr{1, 2}{1, 5}{1, 9}(16,:);...
    ];
YMatrix3=[...
    wa_pr{1, 1}{1, 5}{1, 10}(1,:); wa_pr{1, 2}{1, 5}{1, 10}(1,:);...
    wa_pr{1, 1}{1, 5}{1, 10}(8,:); wa_pr{1, 2}{1, 5}{1, 10}(8,:);...
    wa_pr{1, 1}{1, 5}{1, 10}(16,:); wa_pr{1, 2}{1, 5}{1, 10}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,3,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','Parent',subplot1,'LineWidth',3);
set(plot1(1),'LineStyle',':');
set(plot1(3),'LineStyle',':');
set(plot1(5),'LineStyle',':');
% Create ylabel
ylabel('Renewing Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('NAR');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 10]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot1,[0 100]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,3,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix2)]/10,YMatrix2','Parent',subplot2,'LineWidth',3);
set(plot2(1),'LineStyle',':');
set(plot2(3),'LineStyle',':');
set(plot2(5),'LineStyle',':');
% Create xlabel
xlabel('Distance (km)');
xlim(subplot2,[0 10]);
% Create title
title('SUR');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot2,[0 100]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot3 = subplot(1,3,3,'Parent',figure1);
hold(subplot3,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([1:length(YMatrix3)]/10,YMatrix3','Parent',subplot3,'LineWidth',3);
set(plot3(1),'DisplayName','M, S','LineStyle',':');
set(plot3(2),'DisplayName','P, S');
set(plot3(3),'DisplayName','M, M','LineStyle',':');
set(plot3(4),'DisplayName','P, M');
set(plot3(5),'DisplayName','M, B','LineStyle',':');
set(plot3(6),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
xlim(subplot3,[0 10]);
% Create title
title('TAR');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot3,[0 100]);
box(subplot3,'on');
% Set the remaining axes properties
set(subplot3,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot3,'show');
linkaxes([subplot1, subplot2, subplot3], 'y');
saveas(gcf,'plot_cs_rv_r.png');

%% plot_cs_bn_u.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 2}{1, 1}(1,:); wa_pr{1, 2}{1, 2}{1, 1}(1,:);...
    wa_pr{1, 1}{1, 2}{1, 1}(8,:); wa_pr{1, 2}{1, 2}{1, 1}(8,:);...
    wa_pr{1, 1}{1, 2}{1, 1}(16,:); wa_pr{1, 2}{1, 2}{1, 1}(16,:);...
    ];
YMatrix2=[...
    wa_pr{1, 1}{1, 2}{1, 3}(1,:); wa_pr{1, 2}{1, 2}{1, 3}(1,:);...
    wa_pr{1, 1}{1, 2}{1, 3}(8,:); wa_pr{1, 2}{1, 2}{1, 3}(8,:);...
    wa_pr{1, 1}{1, 2}{1, 3}(16,:); wa_pr{1, 2}{1, 2}{1, 3}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,2,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','Parent',subplot1,'LineWidth',3);
set(plot1(1),'LineStyle',':');
set(plot1(3),'LineStyle',':');
set(plot1(5),'LineStyle',':');
% Create ylabel
ylabel('Upstream Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('Inner bay mouth');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 8]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot1,[0 100]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,2,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix2)]/10,YMatrix2','Parent',subplot2,'LineWidth',3);
set(plot2(1),'DisplayName','M, S','LineStyle',':');
set(plot2(2),'DisplayName','P, S');
set(plot2(3),'DisplayName','M, M','LineStyle',':');
set(plot2(4),'DisplayName','P, M');
set(plot2(5),'DisplayName','M, B','LineStyle',':');
set(plot2(6),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('Outer bay mouth');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot2,[0 21]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot2,[0 100]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot2,'show');
linkaxes([subplot1, subplot2], 'y');
saveas(gcf,'plot_cs_bn_u.png');

% plot_cs_rv_d.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 3}{1, 1}(1,:); wa_pr{1, 2}{1, 3}{1, 1}(1,:);...
    wa_pr{1, 1}{1, 3}{1, 1}(8,:); wa_pr{1, 2}{1, 3}{1, 1}(8,:);...
    wa_pr{1, 1}{1, 3}{1, 1}(16,:); wa_pr{1, 2}{1, 3}{1, 1}(16,:);...
    ];
YMatrix2=[...
    wa_pr{1, 1}{1, 3}{1, 3}(1,:); wa_pr{1, 2}{1, 3}{1, 3}(1,:);...
    wa_pr{1, 1}{1, 3}{1, 3}(8,:); wa_pr{1, 2}{1, 3}{1, 3}(8,:);...
    wa_pr{1, 1}{1, 3}{1, 3}(16,:); wa_pr{1, 2}{1, 3}{1, 3}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,2,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','Parent',subplot1,'LineWidth',3);
set(plot1(1),'LineStyle',':');
set(plot1(3),'LineStyle',':');
set(plot1(5),'LineStyle',':');
% Create ylabel
ylabel('Downstream Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('Inner bay mouth');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 8]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot1,[0 100]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,2,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix2)]/10,YMatrix2','Parent',subplot2,'LineWidth',3);
set(plot2(1),'DisplayName','M, S','LineStyle',':');
set(plot2(2),'DisplayName','P, S');
set(plot2(3),'DisplayName','M, M','LineStyle',':');
set(plot2(4),'DisplayName','P, M');
set(plot2(5),'DisplayName','M, B','LineStyle',':');
set(plot2(6),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
xlim(subplot2,[0 21]);
% Create title
title('Outer bay mouth');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot2,[0 100]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot2,'show');
linkaxes([subplot1, subplot2], 'y');
saveas(gcf,'plot_cs_bn_d.png');

% plot_cs_bn_ud.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 4}{1, 1}(1,:); wa_pr{1, 2}{1, 4}{1, 1}(1,:);...
    wa_pr{1, 1}{1, 4}{1, 1}(8,:); wa_pr{1, 2}{1, 4}{1, 1}(8,:);...
    wa_pr{1, 1}{1, 4}{1, 1}(16,:); wa_pr{1, 2}{1, 4}{1, 1}(16,:);...
    ];
YMatrix2=[...
    wa_pr{1, 1}{1, 4}{1, 3}(1,:); wa_pr{1, 2}{1, 4}{1, 3}(1,:);...
    wa_pr{1, 1}{1, 4}{1, 3}(8,:); wa_pr{1, 2}{1, 4}{1, 3}(8,:);...
    wa_pr{1, 1}{1, 4}{1, 3}(16,:); wa_pr{1, 2}{1, 4}{1, 3}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,2,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','Parent',subplot1,'LineWidth',3);
set(plot1(1),'LineStyle',':');
set(plot1(3),'LineStyle',':');
set(plot1(5),'LineStyle',':');
% Create ylabel
ylabel('U/D (-)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('Inner bay mouth');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 8]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot1,[0 20]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,2,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix2)]/10,YMatrix2','Parent',subplot2,'LineWidth',3);
set(plot2(1),'DisplayName','M, S','LineStyle',':');
set(plot2(2),'DisplayName','P, S');
set(plot2(3),'DisplayName','M, M','LineStyle',':');
set(plot2(4),'DisplayName','P, M');
set(plot2(5),'DisplayName','M, B','LineStyle',':');
set(plot2(6),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
xlim(subplot2,[0 21]);
% Create title
title('Outer bay mouth');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot2,[0 20]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot2,'show');
linkaxes([subplot1, subplot2], 'y');
saveas(gcf,'plot_cs_bn_ud.png');

% plot_cs_bn_r.png
% Create matrix
YMatrix1=[...
    wa_pr{1, 1}{1, 5}{1, 1}(1,:); wa_pr{1, 2}{1, 5}{1, 1}(1,:);...
    wa_pr{1, 1}{1, 5}{1, 1}(8,:); wa_pr{1, 2}{1, 5}{1, 1}(8,:);...
    wa_pr{1, 1}{1, 5}{1, 1}(16,:); wa_pr{1, 2}{1, 5}{1, 1}(16,:);...
    ];
YMatrix2=[...
    wa_pr{1, 1}{1, 5}{1, 3}(1,:); wa_pr{1, 2}{1, 5}{1, 3}(1,:);...
    wa_pr{1, 1}{1, 5}{1, 3}(8,:); wa_pr{1, 2}{1, 5}{1, 3}(8,:);...
    wa_pr{1, 1}{1, 5}{1, 3}(16,:); wa_pr{1, 2}{1, 5}{1, 3}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,2,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1)]/10,YMatrix1','Parent',subplot1,'LineWidth',3);
set(plot1(1),'LineStyle',':');
set(plot1(3),'LineStyle',':');
set(plot1(5),'LineStyle',':');
% Create ylabel
ylabel('Renewing Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('Inner bay mouth');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 8]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot1,[0 100]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,2,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix2)]/10,YMatrix2','Parent',subplot2,'LineWidth',3);
set(plot2(1),'DisplayName','M, S','LineStyle',':');
set(plot2(2),'DisplayName','P, S');
set(plot2(3),'DisplayName','M, M','LineStyle',':');
set(plot2(4),'DisplayName','P, M');
set(plot2(5),'DisplayName','M, B','LineStyle',':');
set(plot2(6),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
xlim(subplot2,[0 21]);
% Create title
title('Outer bay mouth');
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot2,[0 100]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot2,'show');
linkaxes([subplot1, subplot2], 'y');
saveas(gcf,'plot_cs_bn_r.png');