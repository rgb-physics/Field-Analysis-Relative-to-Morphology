%% Quick and dirty: plot quantities stored in sortedMat
% sortedMat is calculated from segmentations and intensity data in
% blobPropsFromTrajs_R_Inertia.m
% 2026-06-01 - Rémi Boros
tFlips = {30,27,24,19,28};
xBnds = [-18 18];
% baseDirs = {'<redacted original absolute path>',...
baseDirs = {'Session 88, Exp 1',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 2',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 3',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 4',...
    % '<redacted original absolute path>'};
    'Session 88, Exp 5'};
% saveSuperDir = '<redacted original absolute path>';
saveSuperDir = 'Session 88';
numInds = numel(baseDirs);

for index = 1:numel(baseDirs)

    baseDir = baseDirs{index};
    dataDir = fullfile(baseDir,'\4 Tracked Blobs');
    dataName = 'trajSorted_BlobVolsInts.mat';
    saveDir = fullfile(baseDir,'Figures','Global Quantities');
    if ~exist(saveDir,'dir')
        mkdir(saveDir);
    end

%% Load
load(fullfile(dataDir,dataName));
if exist(fullfile(dataDir,'metadata.mat'),'dir')
    load(fullfile(dataDir,'metadata.mat'));
end
unqTs = unique(sortedMat(:,2));
imgVol = prod(labelDims.*labelVoxSize);

%% Calculate variance in object densities of grand mean
% Check that variance intensities within objects is comparable to variance
% across objects. Otherwise, no need to add variances within objects
% ogSorted = sortedMat;
% nanInds = ~isnan(sortedMat(:,5));
% sortedMat = sortedMat(nanInds,:);

minVol = 100;
% std of density is std of intensity scaled by volume of a voxel
stdRho_i = ones(size(sortedMat(:,4)));
objVec = stdRho_i;
% objVec = sortedMat(:,6);
% stdRho_i = sortedMat(:,5)/prod(labelVoxSize);
% % stand error for each object is std scaled by (# voxels (samples))^(1/2)
% seRho_i = stdRho_i./sqrt(sortedMat(:,6));

% iterate over time
seMeas = unqTs;    varObjs = unqTs;     seObjs = unqTs;
meanRhos = unqTs;   volFracs = unqTs;   meanVols = unqTs;
for tInd = 1:numel(unqTs)

    currT = unqTs(tInd);
    timeLogic = sortedMat(:,2) == currT;
    volLogic = sortedMat(:,3) > minVol;
    currLogic = timeLogic & volLogic;

    numObjs = sum(currLogic);
    rhoVals = sortedMat(currLogic,4)./sortedMat(currLogic,3);   % (u/um)

    varObjs(tInd) = std(rhoVals).^2;
    seObjs(tInd) = sqrt(varObjs(tInd)/numObjs);
    % Mean variance within objects
    meanVar = mean((stdRho_i(currLogic).^2)./objVec(currLogic));
    seMeas(tInd) = sqrt(meanVar/numObjs);

    meanRhos(tInd) = mean(rhoVals);
    volFracs(tInd) = sum(sortedMat(currLogic,3))/imgVol;
    meanVols(tInd) = mean(sortedMat(currLogic,3));
end
    baseRho = median(meanRhos(1:10));
    pkRho = max(meanRhos);
    % normRhos = (meanRhos - baseRho)/(1);
    normRhos = (meanRhos - baseRho)/(pkRho - baseRho);

% Variance propagation over sum of objects 
%% Plot mean object densities (with errorbars)
figure(1)
tFlip = tFlips{index};
eTimes = (unqTs(1:(tFlip-1))-tFlip)*timeStep;
lTimes = (unqTs(tFlip:end)-tFlip)*timeStep;
rhoScale = 1;
faceColorDark = [.95 .9 .95];
% faceColorDark = [.95*(numInds-index)/numInds .9 .95*(index)/numInds];
faceColorBright = [.4 .4 .4];
% faceColorBright = [.4*(numInds-index)/numInds .4 .4*(index)/numInds];
% figure
% errorbar(eTimes,meanRhos(1:(tFlip-1))*rhoScale,...
%     seObjs(1:(tFlip-1))*rhoScale, 'LineStyle','none', 'Marker','o',...
%     'Color', [.2 .2 .2], 'MarkerFaceColor',[.95 .9 .95],'MarkerEdgeColor',[.8 .4 .8])
scatter(eTimes,meanRhos(1:(tFlip-1))*rhoScale,(6-index)*10,...
    'MarkerFaceColor',faceColorDark,'MarkerEdgeColor',[.8 .4 .8])
hold on
% errorbar(lTimes,meanRhos(tFlip:end)*rhoScale,...
%     seObjs(tFlip:end)*rhoScale, 'LineStyle','none', 'Marker','o',...
%     'Color', [.2 .2 .2], 'MarkerFaceColor',[.4 .4 .4],'MarkerEdgeColor',[.8 .4 .8])
scatter(lTimes,meanRhos(tFlip:end)*rhoScale,(6-index)*10,...
    'MarkerFaceColor',faceColorBright,'MarkerEdgeColor',[.8 .4 .8])
box on
% scatter(unqTs*timeStep,meanRhos*rhoScale,'filled')
ylabel('< \rho_{obj} (\muM) >')
set(gca,'FontSize',15)
% ylim([30 80])
% yticks(40:10:80)
% xlim([min(eTimes) max(lTimes)]*1.1)
xlim(xBnds)
title('Densities')
%% Plot mean object densities renormalized by start and pk density
figure(2)
tFlip = tFlips{index};
eTimes = (unqTs(1:(tFlip-1))-tFlip)*timeStep;
lTimes = (unqTs(tFlip:end)-tFlip)*timeStep;
rhoScale = 1;
% figure
% errorbar(eTimes,meanRhos(1:(tFlip-1))*rhoScale,...
%     seObjs(1:(tFlip-1))*rhoScale, 'LineStyle','none', 'Marker','o',...
%     'Color', [.2 .2 .2], 'MarkerFaceColor',[.95 .9 .95],'MarkerEdgeColor',[.8 .4 .8])
scatter(eTimes,normRhos(1:(tFlip-1))*rhoScale,(6-index)*10,...
    'MarkerFaceColor',faceColorDark,'MarkerEdgeColor',[.8 .4 .8])
hold on
% errorbar(lTimes,meanRhos(tFlip:end)*rhoScale,...
%     seObjs(tFlip:end)*rhoScale, 'LineStyle','none', 'Marker','o',...
%     'Color', [.2 .2 .2], 'MarkerFaceColor',[.4 .4 .4],'MarkerEdgeColor',[.8 .4 .8])
scatter(lTimes,normRhos(tFlip:end)*rhoScale,(6-index)*10,...
    'MarkerFaceColor',faceColorBright,'MarkerEdgeColor',[.8 .4 .8])
box on
% scatter(unqTs*timeStep,meanRhos*rhoScale,'filled')
ylabel('< \rho_{obj} (Normalized) >')
set(gca,'FontSize',15)
% ylim([30 80])
% yticks(40:10:80)
% xlim([min(eTimes) max(lTimes)]*1.1)
xlim(xBnds)
title('Renorm Densities')
%% volume fraction vs time
figure(3)
scatter(eTimes,volFracs(1:(tFlip-1)),(6-index)*10,'Marker','diamond',...
    'MarkerFaceColor',[.95 .9 .95],'MarkerEdgeColor','k')
hold on
scatter(lTimes,volFracs(tFlip:end),(6-index)*10,'Marker','diamond',...
    'MarkerFaceColor',[.2 .2 .2],'MarkerEdgeColor',[.9 .9 .9])
box on
xlabel('Time (min)')
ylabel('\Sigma Vol_{obj} / Vol_{FOV}')
ylim([0 1.1])
yticks(0:.2:1)
set(gca,'FontSize',15)
xlim([min(eTimes) max(lTimes)]*1.1)

xlim(xBnds)
title('Vol Fractions')

end

fileNames = {'OverlayAll_meanRho','OverlayAll_NormRho','OverlayAll_volFrac'};
for index = 1:3
    saveas(figure(index),fullfile(saveSuperDir,sprintf('%s.png',fileNames{index})));
    saveas(figure(index),fullfile(saveSuperDir,sprintf('%s.fig',fileNames{index})));
    saveas(figure(index),fullfile(saveSuperDir,sprintf('%s.svg',fileNames{index})));
end