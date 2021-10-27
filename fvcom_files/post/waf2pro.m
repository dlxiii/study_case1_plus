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
td = load("./wa_dif.mat");
wa_dif = td.wa_dif;
clear td;
if exist('../../wa_files', 'dir')~=7
    mkdir('../../wa_files')
end

%% cross sectional profiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
typelist = {'cu','cd','cud','cr','rud','u_pct','d_pct'};
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

%%
waf_pr = {}; 
% interpolation of topo data
% f=1;
% ncdisp('../../gis_files/present/bathymetry/present_elevation.nc')
% ncdisp('../../gis_files/meiji/bathymetry/meiji_elevation.tif
topodata = ['../../gis_files/present/bathymetry/present_elevation_cut.nc'];
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
    [x,y,z,l] = valOnLine(csv_resol,data_topo,bndlist{b});
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
            Z = wa_dif.(typelist{c}).(mmean{m})(:,:,layer);
            [Y,X] = meshgrid(wa_dif.lat,wa_dif.lon);
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
waf_pr{1}=value;
clear value;
save('waf_pr.mat','waf_pr','-v7.3','-nocompression'); 

%%
% plot river age, consider layer, age type and river name
%       type     u    crs  layer
% wa_pr{1, 2}{1, 2}{1, 4}(1,:)
%       meij     u     i
%       pres     d    io
%              cud     o
%                r    ns
%              rud   ws1
%                    ws2
%                    ws3
%                     r1
%                     r2
%                     r3

%% plot_cs_ns_u.png
%{
% Create matrix
YMatrix1u=[...
    waf_pr{1, 1}{1, 2}{1, 4}(1,:);...
    waf_pr{1, 1}{1, 2}{1, 4}(8,:);...
    waf_pr{1, 1}{1, 2}{1, 4}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1u)]/10,YMatrix1u','LineWidth',3,'Parent',axes1);
set(plot1(1),'DisplayName','S');
set(plot1(2),'DisplayName','M');
set(plot1(3),'DisplayName','B');
% Create ylabel
ylabel('Upstream Age (day)');
ylim([-30,50]);
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
saveas(gcf,'plot_cs_ns_fu.png');

% plot_cs_ns_d.png
% Create matrix
YMatrix1d=[...
    waf_pr{1, 1}{1, 3}{1, 4}(1,:);...
    waf_pr{1, 1}{1, 3}{1, 4}(8,:);...
    waf_pr{1, 1}{1, 3}{1, 4}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1d)]/10,YMatrix1d','LineWidth',3,'Parent',axes1);
set(plot1(1),'DisplayName','S');
set(plot1(2),'DisplayName','M');
set(plot1(3),'DisplayName','B');
% Create ylabel
ylabel('Downstream Age (day)');
ylim([-30,50]);
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
saveas(gcf,'plot_cs_ns_fd.png');

% plot_cs_ns_r.png
% Create matrix
YMatrix1r=[...
    waf_pr{1, 1}{1, 5}{1, 4}(1,:);...
    waf_pr{1, 1}{1, 5}{1, 4}(8,:);...
    waf_pr{1, 1}{1, 5}{1, 4}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1r)]/10,YMatrix1r','LineWidth',3,'Parent',axes1);
set(plot1(1),'DisplayName','S');
set(plot1(2),'DisplayName','M');
set(plot1(3),'DisplayName','B');
% Create ylabel
ylabel('Renewing Age (day)');
ylim([-30,50]);
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
saveas(gcf,'plot_cs_ns_fr.png');

% plot_cs_ns_ud.png
% Create matrix
YMatrix1ud=[...
    waf_pr{1, 1}{1, 4}{1, 4}(1,:);...
    waf_pr{1, 1}{1, 4}{1, 4}(8,:);...
    waf_pr{1, 1}{1, 4}{1, 4}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1ud)]/10,YMatrix1ud','LineWidth',3,'Parent',axes1);
set(plot1(1),'DisplayName','S');
set(plot1(2),'DisplayName','M');
set(plot1(3),'DisplayName','B');
% Create ylabel
ylabel('U/D (-)');
ylim([-1,2]);
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
saveas(gcf,'plot_cs_ns_fud.png');


%% plot_cs_we_u.png
% Create matrix
YMatrix11u=[...
    waf_pr{1, 1}{1, 2}{1, 5}(1,:);...
    waf_pr{1, 1}{1, 2}{1, 5}(8,:);...
    waf_pr{1, 1}{1, 2}{1, 5}(16,:);...
    ];
YMatrix21u=[...
    waf_pr{1, 1}{1, 2}{1, 6}(1,:);...
    waf_pr{1, 1}{1, 2}{1, 6}(8,:);...
    waf_pr{1, 1}{1, 2}{1, 6}(16,:);...
    ];
YMatrix31u=[...
    waf_pr{1, 1}{1, 2}{1, 7}(1,:);...
    waf_pr{1, 1}{1, 2}{1, 7}(8,:);...
    waf_pr{1, 1}{1, 2}{1, 7}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,3,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix11u)]/10,YMatrix11u','Parent',subplot1,'LineWidth',3);
% Create ylabel
ylabel('Upstream Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE1');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 17]);
% Uncomment the following line to preserve the Y-limits of the axes
% ylim(subplot1,[0 100]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,3,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix21u)]/10,YMatrix21u','Parent',subplot2,'LineWidth',3);
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE2');
% Uncomment the following line to preserve the Y-limits of the axes
% ylim(subplot2,[0 100]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot3 = subplot(1,3,3,'Parent',figure1);
hold(subplot3,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([1:length(YMatrix31u)]/10,YMatrix31u','Parent',subplot3,'LineWidth',3);
set(plot3(1),'DisplayName','S');
set(plot3(2),'DisplayName','M');
set(plot3(3),'DisplayName','B');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE3');
% Uncomment the following line to preserve the Y-limits of the axes
% ylim(subplot3,[0 100]);
box(subplot3,'on');
% Set the remaining axes properties
set(subplot3,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot3,'show');
linkaxes([subplot1, subplot2, subplot3], 'y');
saveas(gcf,'plot_cs_we_fu.png');

% plot_cs_we_d.png
% Create matrix
YMatrix11d=[...
    waf_pr{1, 1}{1, 3}{1, 5}(1,:);...
    waf_pr{1, 1}{1, 3}{1, 5}(8,:);...
    waf_pr{1, 1}{1, 3}{1, 5}(16,:);...
    ];
YMatrix21d=[...
    waf_pr{1, 1}{1, 3}{1, 6}(1,:);...
    waf_pr{1, 1}{1, 3}{1, 6}(8,:);...
    waf_pr{1, 1}{1, 3}{1, 6}(16,:);...
    ];
YMatrix31d=[...
    waf_pr{1, 1}{1, 3}{1, 7}(1,:);...
    waf_pr{1, 1}{1, 3}{1, 7}(8,:);...
    waf_pr{1, 1}{1, 3}{1, 7}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,3,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix11d)]/10,YMatrix11d','Parent',subplot1,'LineWidth',3);
% Create ylabel
ylabel('Downstream Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE1');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 17]);
% Uncomment the following line to preserve the Y-limits of the axes
% ylim(subplot1,[0 100]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,3,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix21d)]/10,YMatrix21d','Parent',subplot2,'LineWidth',3);
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE2');
% Uncomment the following line to preserve the Y-limits of the axes
% ylim(subplot2,[0 100]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot3 = subplot(1,3,3,'Parent',figure1);
hold(subplot3,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([1:length(YMatrix31d)]/10,YMatrix31d','Parent',subplot3,'LineWidth',3);
set(plot3(1),'DisplayName','P, S');
set(plot3(2),'DisplayName','P, M');
set(plot3(3),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE3');
% Uncomment the following line to preserve the Y-limits of the axes
% ylim(subplot3,[0 100]);
box(subplot3,'on');
% Set the remaining axes properties
set(subplot3,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot3,'show');
linkaxes([subplot1, subplot2, subplot3], 'y');
saveas(gcf,'plot_cs_we_d.png');

% plot_cs_we_ud.png
% Create matrix
YMatrix11ud=[...
    waf_pr{1, 1}{1, 4}{1, 5}(1,:);...
    waf_pr{1, 1}{1, 4}{1, 5}(8,:);...
    waf_pr{1, 1}{1, 4}{1, 5}(16,:);...
    ];
YMatrix21ud=[...
    waf_pr{1, 1}{1, 4}{1, 6}(1,:);...
    waf_pr{1, 1}{1, 4}{1, 6}(8,:);...
    waf_pr{1, 1}{1, 4}{1, 6}(16,:);...
    ];
YMatrix31ud=[...
    waf_pr{1, 1}{1, 4}{1, 7}(1,:);...
    waf_pr{1, 1}{1, 4}{1, 7}(8,:);...
    waf_pr{1, 1}{1, 4}{1, 7}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,3,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix11ud)]/10,YMatrix11ud','Parent',subplot1,'LineWidth',3);
% Create ylabel
ylabel('U/D (-)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE1');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 17]);
% Uncomment the following line to preserve the Y-limits of the axes
%ylim(subplot1,[0 3]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,3,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix21ud)]/10,YMatrix21ud','Parent',subplot2,'LineWidth',3);
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE2');
% Uncomment the following line to preserve the Y-limits of the axes
%ylim(subplot2,[0 3]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot3 = subplot(1,3,3,'Parent',figure1);
hold(subplot3,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([1:length(YMatrix31ud)]/10,YMatrix31ud','Parent',subplot3,'LineWidth',3);
set(plot3(1),'DisplayName','P, S');
set(plot3(2),'DisplayName','P, M');
set(plot3(3),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE3');
% Uncomment the following line to preserve the Y-limits of the axes
%ylim(subplot3,[0 3]);
box(subplot3,'on');
% Set the remaining axes properties
set(subplot3,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot3,'show');
linkaxes([subplot1, subplot2, subplot3], 'y');
saveas(gcf,'plot_cs_we_ud.png');

% plot_cs_ws_r.png
% Create matrix
YMatrix11r=[...
    waf_pr{1, 1}{1, 5}{1, 5}(1,:);...
    waf_pr{1, 1}{1, 5}{1, 5}(8,:);...
    waf_pr{1, 1}{1, 5}{1, 5}(16,:);...
    ];
YMatrix21r=[...
    waf_pr{1, 1}{1, 5}{1, 6}(1,:);...
    waf_pr{1, 1}{1, 5}{1, 6}(8,:);...
    waf_pr{1, 1}{1, 5}{1, 6}(16,:);...
    ];
YMatrix31r=[...
    waf_pr{1, 1}{1, 5}{1, 7}(1,:);...
    waf_pr{1, 1}{1, 5}{1, 7}(8,:);...
    waf_pr{1, 1}{1, 5}{1, 7}(16,:);...
    ];
% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[560 420];
% Create subplot
subplot1 = subplot(1,3,1,'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix11r)]/10,YMatrix11r','Parent',subplot1,'LineWidth',3);
% Create ylabel
ylabel('Renewing Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE1');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 17]);
% Uncomment the following line to preserve the Y-limits of the axes
%ylim(subplot1,[0 100]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot2 = subplot(1,3,2,'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix21r)]/10,YMatrix21r','Parent',subplot2,'LineWidth',3);
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE2');
% Uncomment the following line to preserve the Y-limits of the axes
%ylim(subplot2,[0 100]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');
% Create subplot
subplot3 = subplot(1,3,3,'Parent',figure1);
hold(subplot3,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([1:length(YMatrix31r)]/10,YMatrix31r','Parent',subplot3,'LineWidth',3);
set(plot3(1),'DisplayName','P, S');
set(plot3(2),'DisplayName','P, M');
set(plot3(3),'DisplayName','P, B');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('WE3');
% Uncomment the following line to preserve the Y-limits of the axes
%ylim(subplot3,[0 100]);
box(subplot3,'on');
% Set the remaining axes properties
set(subplot3,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend(subplot3,'show');
linkaxes([subplot1, subplot2, subplot3], 'y');
saveas(gcf,'plot_cs_we_r.png');


%% axis cross section

% Create figure
figure1 = figure;
figure1.Position(3:4) = 1.5*[840 420];

% Create subplot
subplot1 = subplot(3,6,[1,2,3],'Parent',figure1);
hold(subplot1,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix1u)]/10,YMatrix1u(1,:)',...
    [1:length(YMatrix1d)]/10,YMatrix1d(1,:)',...
    [1:length(YMatrix1r)]/10,YMatrix1r(1,:)',...
    'Parent',subplot1,'LineWidth',3);
set(plot1(1),'DisplayName','Upstream');
set(plot1(2),'DisplayName','Downstream');
set(plot1(3),'DisplayName','Renewing');
% Create ylabel
ylabel('Age change (day)');
% Create xlabel
% xlabel('Distance (km)');
% Create title
title('NS');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot1,[0 55]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot1,[-25 50]);
box(subplot1,'on');
% Set the remaining axes properties
set(subplot1,'FontSize',16,'XGrid','on','YGrid','on');
% Create legend
legend1 = legend(subplot1,'show');
set(legend1,'Orientation','horizontal','Location','southeast');

% Create subplot
subplot2 = subplot(3,6,[7,8,9],'Parent',figure1);
hold(subplot2,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix1u)]/10,YMatrix1u(2,:)',...
    [1:length(YMatrix1d)]/10,YMatrix1d(2,:)',...
    [1:length(YMatrix1r)]/10,YMatrix1r(2,:)',...
    'Parent',subplot2,'LineWidth',3);
% Create ylabel
ylabel('Age change (day)');
% Create xlabel
% xlabel('Distance (km)');
% Create title
title('');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot2,[0 55]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot2,[-25 50]);
box(subplot2,'on');
% Set the remaining axes properties
set(subplot2,'FontSize',16,'XGrid','on','YGrid','on');

% Create subplot
subplot3 = subplot(3,6,[13,14,15],'Parent',figure1);
hold(subplot3,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([1:length(YMatrix1u)]/10,YMatrix1u(3,:)',...
    [1:length(YMatrix1d)]/10,YMatrix1d(3,:)',...
    [1:length(YMatrix1r)]/10,YMatrix1r(3,:)',...
    'Parent',subplot3,'LineWidth',3);
% Create ylabel
ylabel('Age change (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot3,[0 55]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot3,[-25 50]);
box(subplot3,'on');
% Set the remaining axes properties
set(subplot3,'FontSize',16,'XGrid','on','YGrid','on');

linkaxes([subplot1, subplot2, subplot3], 'x');

% Create subplot
subplot4 = subplot(3,6,4,'Parent',figure1);
hold(subplot4,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([1:length(YMatrix11u)]/10,YMatrix11u(1,:)',...
    [1:length(YMatrix11d)]/10,YMatrix11d(1,:)',...
    [1:length(YMatrix11r)]/10,YMatrix11r(1,:)',...
    'Parent',subplot4,'LineWidth',3);
% Create ylabel
%ylabel('Upstream Age (day)');
% Create xlabel
% xlabel('Distance (km)');
% Create title
title('WE1');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot4,[0 17]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot4,[-25 50]);
box(subplot4,'on');
% Set the remaining axes properties
set(subplot4,'FontSize',16,'XGrid','on','YGrid','on');

% Create subplot
subplot5 = subplot(3,6,10,'Parent',figure1);
hold(subplot5,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([1:length(YMatrix11u)]/10,YMatrix11u(2,:)',...
    [1:length(YMatrix11d)]/10,YMatrix11d(2,:)',...
    [1:length(YMatrix11r)]/10,YMatrix11r(2,:)',...
    'Parent',subplot5,'LineWidth',3);
% Create ylabel
%ylabel('Downstream Age (day)');
% Create xlabel
% xlabel('Distance (km)');
% Create title
title('');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot5,[0 17]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot5,[-25 50]);
box(subplot5,'on');
% Set the remaining axes properties
set(subplot5,'FontSize',16,'XGrid','on','YGrid','on');

% Create subplot
subplot6 = subplot(3,6,16,'Parent',figure1);
hold(subplot6,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([1:length(YMatrix11u)]/10,YMatrix11u(3,:)',...
    [1:length(YMatrix11d)]/10,YMatrix11d(3,:)',...
    [1:length(YMatrix11r)]/10,YMatrix11r(3,:)',...
    'Parent',subplot6,'LineWidth',3);
% Create ylabel
% ylabel('Renewing Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot6,[0 17]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot6,[-25 50]);
box(subplot6,'on');
% Set the remaining axes properties
set(subplot6,'FontSize',16,'XGrid','on','YGrid','on');

linkaxes([subplot4, subplot5, subplot6], 'x');

% Create subplot
subplot7 = subplot(3,6,5,'Parent',figure1);
hold(subplot7,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([length(YMatrix21u):-1:1]/10,YMatrix21u(1,:)',...
    [length(YMatrix21d):-1:1]/10,YMatrix21d(1,:)',...
    [length(YMatrix21r):-1:1]/10,YMatrix21r(1,:)',...
    'Parent',subplot7,'LineWidth',3);
% Create ylabel
%ylabel('Upstream Age (day)');
% Create xlabel
% xlabel('Distance (km)');
% Create title
title('WE2');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot7,[0 15]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot7,[-25 50]);
box(subplot7,'on');
% Set the remaining axes properties
set(subplot7,'FontSize',16,'XGrid','on','YGrid','on');

% Create subplot
subplot8 = subplot(3,6,11,'Parent',figure1);
hold(subplot8,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([length(YMatrix21u):-1:1]/10,YMatrix21u(2,:)',...
    [length(YMatrix21d):-1:1]/10,YMatrix21d(2,:)',...
    [length(YMatrix21r):-1:1]/10,YMatrix21r(2,:)',...
    'Parent',subplot8,'LineWidth',3);
% Create ylabel
%ylabel('Downstream Age (day)');
% Create xlabel
% xlabel('Distance (km)');
% Create title
title('');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot8,[0 15]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot8,[-25 50]);
box(subplot8,'on');
% Set the remaining axes properties
set(subplot8,'FontSize',16,'XGrid','on','YGrid','on');

% Create subplot
subplot9 = subplot(3,6,17,'Parent',figure1);
hold(subplot9,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([length(YMatrix21u):-1:1]/10,YMatrix21u(3,:)',...
    [length(YMatrix21d):-1:1]/10,YMatrix21d(3,:)',...
    [length(YMatrix21r):-1:1]/10,YMatrix21r(3,:)',...
    'Parent',subplot9,'LineWidth',3);
% Create ylabel
% ylabel('Renewing Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot9,[0 15]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot9,[-25 50]);
box(subplot9,'on');
% Set the remaining axes properties
set(subplot9,'FontSize',16,'XGrid','on','YGrid','on');

linkaxes([subplot7, subplot8, subplot9], 'x');

% Create subplot
subplot10 = subplot(3,6,6,'Parent',figure1);
hold(subplot10,'on');
% Create multiple lines using matrix input to plot
plot1 = plot([length(YMatrix31u):-1:1]/10,YMatrix31u(1,:)',...
    [length(YMatrix31d):-1:1]/10,YMatrix31d(1,:)',...
    [length(YMatrix31r):-1:1]/10,YMatrix31r(1,:)',...
    'Parent',subplot10,'LineWidth',3);
% Create ylabel
%ylabel('Upstream Age (day)');
% Create xlabel
% xlabel('Distance (km)');
% Create title
title('WE3');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot10,[0 15]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot10,[-25 50]);
box(subplot10,'on');
% Set the remaining axes properties
set(subplot10,'FontSize',16,'XGrid','on','YGrid','on');

% Create subplot
subplot11 = subplot(3,6,12,'Parent',figure1);
hold(subplot11,'on');
% Create multiple lines using matrix input to plot
plot2 = plot([length(YMatrix31u):-1:1]/10,YMatrix31u(2,:)',...
    [length(YMatrix31d):-1:1]/10,YMatrix31d(2,:)',...
    [length(YMatrix31r):-1:1]/10,YMatrix31r(2,:)',...
    'Parent',subplot11,'LineWidth',3);
% Create ylabel
%ylabel('Downstream Age (day)');
% Create xlabel
% xlabel('Distance (km)');
% Create title
title('');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot11,[0 15]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot11,[-25 50]);
box(subplot11,'on');
% Set the remaining axes properties
set(subplot11,'FontSize',16,'XGrid','on','YGrid','on');

% Create subplot
subplot12 = subplot(3,6,18,'Parent',figure1);
hold(subplot12,'on');
% Create multiple lines using matrix input to plot
plot3 = plot([length(YMatrix31u):-1:1]/10,YMatrix31u(3,:)',...
    [length(YMatrix31d):-1:1]/10,YMatrix31d(3,:)',...
    [length(YMatrix31r):-1:1]/10,YMatrix31r(3,:)',...
    'Parent',subplot12,'LineWidth',3);
% Create ylabel
% ylabel('Renewing Age (day)');
% Create xlabel
xlabel('Distance (km)');
% Create title
title('');
% Uncomment the following line to preserve the X-limits of the axes
xlim(subplot12,[0 15]);
% Uncomment the following line to preserve the Y-limits of the axes
ylim(subplot12,[-25 50]);
box(subplot12,'on');
% Set the remaining axes properties
set(subplot12,'FontSize',16,'XGrid','on','YGrid','on');

linkaxes([subplot10, subplot11, subplot12], 'x');

saveas(gcf,'plot_ns&we.png');
%}

%% bay mouths sections cud

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
close all;
l = 840;

n = 4;
f = scoordF(...
    waf_pr{1, 1}{1, 1}{1, n}(:,3)',...
    waf_pr{1, 1}{1, 4}{1, n},...
    20,0.1,...
    -0.3,1.3,0.2);
f.Position(3:4) = 1.5*[l l/4];
saveas(gcf,'plot_cudc_pro_ns.png');

n = 5;
f = scoordF(...
    waf_pr{1, 1}{1, 1}{1, n}(:,3)',...
    waf_pr{1, 1}{1, 4}{1, n},...
    20,0.1,...
    -0.3,1.3,0.2);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_cudc_pro_we1.png');

n = 6;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 4}{1, n}),...
    20,0.1,...
    -0.3,1.3,0.2);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_cudc_pro_we2.png');

n = 7;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 4}{1, n}),...
    20,0.1,...
    -0.3,1.3,0.2);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_cudc_pro_we3.png');

%%%

n = 1;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 4}{1, n}),...
    20,0.1,...
    -0.5,1.5,0.5);
f.Position(3:4) = 1.5*[l/2 l/4];
saveas(gcf,'plot_cudc_pro_bin.png');

n = 3;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 4}{1, n}),...
    20,0.1,...
    -1,4,0.5);
f.Position(3:4) = 1.5*[l/2 l/4];
saveas(gcf,'plot_cudc_pro_bou.png');

n = 2;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 4}{1, n}),...
    20,0.1,...
    -1,4,0.5);
f.Position(3:4) = 1.5*[l l/4];
saveas(gcf,'plot_cudc_pro_bio.png');

%% bay mouths sections u

close all;
l = 840;

n = 4;
f = scoordF(...
    waf_pr{1, 1}{1, 1}{1, n}(:,3)',...
    waf_pr{1, 1}{1, 2}{1, n},...
    20,0.1,...
    -20,50,10);
f.Position(3:4) = 1.5*[l l/4];
saveas(gcf,'plot_uc_pro_ns.png');

n = 5;
f = scoordF(...
    waf_pr{1, 1}{1, 1}{1, n}(:,3)',...
    waf_pr{1, 1}{1, 2}{1, n},...
    20,0.1,...
    -20,50,10);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_uc_pro_we1.png');

n = 6;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 2}{1, n}),...
    20,0.1,...
    -20,50,10);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_uc_pro_we2.png');

n = 7;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 2}{1, n}),...
    20,0.1,...
    -20,50,10);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_uc_pro_we3.png');

%%%

n = 1;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 2}{1, n}),...
    20,0.1,...
    -20,50,10);
f.Position(3:4) = 1.5*[l/2 l/4];
saveas(gcf,'plot_uc_pro_bin.png');

n = 3;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 2}{1, n}),...
    20,0.1,...
    -20,50,10);
f.Position(3:4) = 1.5*[l/2 l/4];
saveas(gcf,'plot_uc_pro_bou.png');

n = 2;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 2}{1, n}),...
    20,0.1,...
    -20,50,10);
f.Position(3:4) = 1.5*[l l/4];
saveas(gcf,'plot_uc_pro_bio.png');

%% bay mouths sections d

close all;
l = 840;

n = 4;
f = scoordF(...
    waf_pr{1, 1}{1, 1}{1, n}(:,3)',...
    waf_pr{1, 1}{1, 3}{1, n},...
    20,0.1,...
    -20,50,10);
f.Position(3:4) = 1.5*[l l/4];
saveas(gcf,'plot_dc_pro_ns.png');

n = 5;
f = scoordF(...
    waf_pr{1, 1}{1, 1}{1, n}(:,3)',...
    waf_pr{1, 1}{1, 3}{1, n},...
    20,0.1,...
    -20,50,10);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_dc_pro_we1.png');

n = 6;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 3}{1, n}),...
    20,0.1,...
    -20,50,10);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_dc_pro_we2.png');

n = 7;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 3}{1, n}),...
    20,0.1,...
    -20,50,10);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_dc_pro_we3.png');

%%%

n = 1;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 3}{1, n}),...
    20,0.1,...
    -20,50,5);
f.Position(3:4) = 1.5*[l/2 l/4];
saveas(gcf,'plot_dc_pro_bin.png');

n = 3;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 3}{1, n}),...
    20,0.1,...
    -20,50,5);
f.Position(3:4) = 1.5*[l/2 l/4];
saveas(gcf,'plot_dc_pro_bou.png');

n = 2;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 3}{1, n}),...
    20,0.1,...
    -20,50,5);
f.Position(3:4) = 1.5*[l l/4];
saveas(gcf,'plot_dc_pro_bio.png');


%% bay mouths sections rud

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
close all;
l = 840;

n = 4;
f = scoordF(...
    waf_pr{1, 1}{1, 1}{1, n}(:,3)',...
    waf_pr{1, 1}{1, 6}{1, n},...
    20,0.1,...
    -5,7,1);
f.Position(3:4) = 1.5*[l l/4];
saveas(gcf,'plot_rudc_pro_ns.png');

n = 5;
f = scoordF(...
    waf_pr{1, 1}{1, 1}{1, n}(:,3)',...
    waf_pr{1, 1}{1, 6}{1, n},...
    20,0.1,...
    -0.3,1.3,0.2);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_rudc_pro_we1.png');

n = 6;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 6}{1, n}),...
    20,0.1,...
    -0.3,1.3,0.2);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_rudc_pro_we2.png');

n = 7;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 6}{1, n}),...
    20,0.1,...
    -0.3,1.3,0.2);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_rudc_pro_we3.png');

%%%

n = 1;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 6}{1, n}),...
    20,0.1,...
    -0.5,1.5,0.5);
f.Position(3:4) = 1.5*[l/2 l/4];
saveas(gcf,'plot_rudc_pro_bin.png');

n = 3;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 6}{1, n}),...
    20,0.1,...
    -1,4,0.5);
f.Position(3:4) = 1.5*[l/2 l/4];
saveas(gcf,'plot_rudc_pro_bou.png');

n = 2;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 6}{1, n}),...
    20,0.1,...
    -1,4,0.5);
f.Position(3:4) = 1.5*[l l/4];
saveas(gcf,'plot_rudc_pro_bio.png');


%% bay mouths sections delta u_pct%

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
close all;
l = 840;

n = 4;
f = scoordF(...
    waf_pr{1, 1}{1, 1}{1, n}(:,3)',...
    100*waf_pr{1, 1}{1, 7}{1, n},...
    20,0.1,...
    100*-0.3,100*1.0,100*0.2);
f.Position(3:4) = 1.5*[l l/4];
saveas(gcf,'plot_upct_pro_ns.png');

n = 5;
f = scoordF(...
    waf_pr{1, 1}{1, 1}{1, n}(:,3)',...
    waf_pr{1, 1}{1, 7}{1, n},...
    20,0.1,...
    -0.3,1.0,0.1);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_upct_pro_we1.png');

n = 6;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 7}{1, n}),...
    20,0.1,...
    -0.3,1.0,0.1);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_upct_pro_we2.png');

n = 7;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 7}{1, n}),...
    20,0.1,...
    -0.3,1.0,0.1);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_upct_pro_we3.png');

%%%

n = 1;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 7}{1, n}),...
    20,0.1,...
    -0.3,1.0,0.1);
f.Position(3:4) = 1.5*[l/2 l/4];
saveas(gcf,'plot_upct_pro_bin.png');

n = 3;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 7}{1, n}),...
    20,0.1,...
    -0.3,1.0,0.1);
f.Position(3:4) = 1.5*[l/2 l/4];
saveas(gcf,'plot_upct_pro_bou.png');

n = 2;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 7}{1, n}),...
    20,0.1,...
    -0.3,1.0,0.1);
f.Position(3:4) = 1.5*[l l/4];
saveas(gcf,'plot_upct_pro_bio.png');

%% bay mouths sections delta d_pct%

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
close all;
l = 840;

n = 4;
f = scoordF(...
    waf_pr{1, 1}{1, 1}{1, n}(:,3)',...
    waf_pr{1, 1}{1, 8}{1, n},...
    20,0.1,...
    -0.3,1.0,0.1);
f.Position(3:4) = 1.5*[l l/4];
saveas(gcf,'plot_dpct_pro_ns.png');

n = 5;
f = scoordF(...
    waf_pr{1, 1}{1, 1}{1, n}(:,3)',...
    waf_pr{1, 1}{1, 8}{1, n},...
    20,0.1,...
    -0.3,1.0,0.1);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_dpct_pro_we1.png');

n = 6;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 8}{1, n}),...
    20,0.1,...
    -0.3,1.0,0.1);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_dpct_pro_we2.png');

n = 7;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 8}{1, n}),...
    20,0.1,...
    -0.3,1.0,0.1);
f.Position(3:4) = 1.5*[l/3 l/4];
saveas(gcf,'plot_dpct_pro_we3.png');

%%%

n = 1;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 8}{1, n}),...
    20,0.1,...
    -0.3,1.0,0.1);
f.Position(3:4) = 1.5*[l/2 l/4];
saveas(gcf,'plot_dpct_pro_bin.png');

n = 3;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 8}{1, n}),...
    20,0.1,...
    -0.3,1.0,0.1);
f.Position(3:4) = 1.5*[l/2 l/4];
saveas(gcf,'plot_dpct_pro_bou.png');

n = 2;
f = scoordF(...
    fliplr(waf_pr{1, 1}{1, 1}{1, n}(:,3)'),...
    fliplr(waf_pr{1, 1}{1, 8}{1, n}),...
    20,0.1,...
    -0.3,1.0,0.1);
f.Position(3:4) = 1.5*[l l/4];
saveas(gcf,'plot_dpct_pro_bio.png');