%% Very crude, very fast, mean proeprties from structures over time
% 2026-05-26 - Rémi Boros

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
volsIntsName = 'ALL_trajSorted_BlobVolsInts.mat';
rsAnisName = 'ALL_trajSorted_RMin_Anisotropy.mat';

%% Load
load(fullfile(dataDir,volsIntsName));
load(fullfile(dataDir,rsAnisName));

%% Concatenate data
unqTs = unique(sortedMat(:,2));
meanRhos = zeros(numel(unqTs),1);
volFracs = meanRhos;

for index = 1:numel(unqTs)

    currT = unqTs(index);
    currLogic = sortedMat(:,2) == currT;
    % Average intensity/volume of each object
    meanRhos(index) = mean(sortedMat(currLogic,4)./sortedMat(currLogic,3));
    % Ratio of total object volumes over image size scaled by voxel size
    volFracs(index) = sum(sortedMat(currLogic,3))/prod(imgDims.*imgVoxSize);

end

%% Scatter plot - overlay
tFlip = 25;
rhoScale = 42/480;
figure
scatter(unqTs(1:(tFlip-1))*timeStep,volFracs(1:(tFlip-1)),'Marker','diamond',...
    'MarkerFaceColor',[.95 .9 .95],'MarkerEdgeColor','k')
hold on
scatter(unqTs(tFlip:end)*timeStep,volFracs(tFlip:end),'Marker','diamond',...
    'MarkerFaceColor',[.4 .4 .4],'MarkerEdgeColor','k')
box on
xlabel('Time (min)')
ylabel('\Sigma Vol_{obj} / Vol_{FOV}')
yyaxis right
scatter(unqTs(1:(tFlip-1))*timeStep,meanRhos(1:(tFlip-1))*rhoScale,...
    'MarkerFaceColor',[.95 .9 .95],'MarkerEdgeColor',[.8 .4 .8])
hold on
scatter(unqTs(tFlip:end)*timeStep,meanRhos(tFlip:end)*rhoScale,...
    'MarkerFaceColor',[.4 .4 .4],'MarkerEdgeColor',[.8 .4 .8])
% scatter(unqTs*timeStep,meanRhos*rhoScale,'filled')
ylabel('< \rho_{obj} (\muM) >')
temp = gca; temp.YColor = 'k';
set(gca,'FontSize',15)

%% Scatter plot - separate
tFlip = 25;
rhoScale = 42/480;
figure
scatter(unqTs(1:(tFlip-1))*timeStep,volFracs(1:(tFlip-1)),'Marker','diamond',...
    'MarkerFaceColor',[.95 .9 .95],'MarkerEdgeColor','k')
hold on
scatter(unqTs(tFlip:end)*timeStep,volFracs(tFlip:end),'Marker','diamond',...
    'MarkerFaceColor',[.2 .2 .2],'MarkerEdgeColor','k')
box on
xlabel('Time (min)')
ylabel('\Sigma Vol_{obj} / Vol_{FOV}')
ylim([0 1.1])
yticks(0:.2:1)
set(gca,'FontSize',15)

figure
scatter(unqTs(1:(tFlip-1))*timeStep,meanRhos(1:(tFlip-1))*rhoScale,...
    'MarkerFaceColor',[.95 .9 .95],'MarkerEdgeColor',[.8 .4 .8])
hold on
scatter(unqTs(tFlip:end)*timeStep,meanRhos(tFlip:end)*rhoScale,...
    'MarkerFaceColor',[.4 .4 .4],'MarkerEdgeColor',[.8 .4 .8])
box on
% scatter(unqTs*timeStep,meanRhos*rhoScale,'filled')
ylabel('< \rho_{obj} (\muM) >')
set(gca,'FontSize',15)
ylim([30 80])
yticks(40:10:80)

