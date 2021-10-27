month = {'14_09','14_10','14_11','14_12',...
    '15_01','15_02','15_03','15_04','15_05','15_06',...
    '15_07','15_08'};
verb = {'rho1','u','v'};

clear TD temp;
for v = 1:length(verb)
    temp = load(['ncfile_',verb{v},'_m.mat']);
    for m = 1:length(month)
        TD.([verb{v},month{m}]) = temp.TD.([verb{v},month{m}]);
    end
end
TD.lon = temp.TD.lon;
TD.lat = temp.TD.lat;
TD.lonc = temp.TD.lonc;
TD.latc = temp.TD.latc;

save('ncfile_stuv.mat','TD','-v7.3','-nocompression');
