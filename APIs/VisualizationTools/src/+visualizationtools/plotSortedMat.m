%% Quick and dirty: plot quantities stored in sortedMat
% sortedMat is calculated from segmentations and intensity data in
% blobPropsFromTrajs_R_Inertia.m
% 2026-06-01 - Rémi Boros

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 88, Exp 5';
dataName = 'trajSorted_BlobVolsInts.mat';

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

% Variance propagation over sum of objects 
%% Plot mean object densities with errorbars
figure
tFlip = 28;
eTimes = (unqTs(1:(tFlip-1))-tFlip)*timeStep;
lTimes = (unqTs(tFlip:end)-tFlip)*timeStep;
rhoScale = 42/480;
% figure
errorbar(eTimes,meanRhos(1:(tFlip-1))*rhoScale,...
    seObjs(1:(tFlip-1))*rhoScale, 'LineStyle','none', 'Marker','o',...
    'Color', [.2 .2 .2], 'MarkerFaceColor',[.95 .9 .95],'MarkerEdgeColor',[.8 .4 .8])
% scatter(unqTs(1:(tFlip-1))*timeStep,meanRhos(1:(tFlip-1))*rhoScale,...
%     'MarkerFaceColor',[.95 .9 .95],'MarkerEdgeColor',[.8 .4 .8])
hold on
errorbar(lTimes,meanRhos(tFlip:end)*rhoScale,...
    seObjs(tFlip:end)*rhoScale, 'LineStyle','none', 'Marker','o',...
    'Color', [.2 .2 .2], 'MarkerFaceColor',[.4 .4 .4],'MarkerEdgeColor',[.8 .4 .8])
% scatter(unqTs(tFlip:end)*timeStep,meanRhos(tFlip:end)*rhoScale,...
%     'MarkerFaceColor',[.4 .4 .4],'MarkerEdgeColor',[.8 .4 .8])
box on
% scatter(unqTs*timeStep,meanRhos*rhoScale,'filled')
ylabel('< \rho_{obj} (\muM) >')
set(gca,'FontSize',15)
% ylim([30 80])
% yticks(40:10:80)
xlim([min(eTimes) max(lTimes)]*1.1)

%% volume fraction vs time
figure
scatter(eTimes,volFracs(1:(tFlip-1)),'Marker','diamond',...
    'MarkerFaceColor',[.95 .9 .95],'MarkerEdgeColor','k')
hold on
scatter(lTimes,volFracs(tFlip:end),'Marker','diamond',...
    'MarkerFaceColor',[.2 .2 .2],'MarkerEdgeColor','k')
box on
xlabel('Time (min)')
ylabel('\Sigma Vol_{obj} / Vol_{FOV}')
ylim([0 1.1])
yticks(0:.2:1)
set(gca,'FontSize',15)
xlim([min(eTimes) max(lTimes)]*1.1)

%% volume fraction vs time
figure
scatter(eTimes,meanVols(1:(tFlip-1)),'Marker','diamond',...
    'MarkerFaceColor',[.95 .9 .95],'MarkerEdgeColor','k')
hold on
scatter(lTimes,meanVols(tFlip:end),'Marker','diamond',...
    'MarkerFaceColor',[.2 .2 .2],'MarkerEdgeColor','k')
box on
xlabel('Time (min)')
ylabel('\Sigma Vol_{obj} / Vol_{FOV}')
% ylim([0 1.1])
yticks(0:.2:1)
set(gca,'FontSize',15)
xlim([min(eTimes) max(lTimes)]*1.1)
