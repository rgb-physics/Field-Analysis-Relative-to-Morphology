%% Takes in data calculated from blobDensityDeltaR_Skels.m
% 2026-06-24 - Rémi Boros
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 3';
dataName = 'ints_vols_overDeltaR.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

%% Load data
load(fullfile(dataDir,dataName));
load(fullfile(dataDir,'metadata.mat'));
deltaT = 0.5;
frameZero = 34;

%% Plot distributions
concFracMT = 42/1670;
concFracK4 = 290/315;
subTimes = sort([14:4:42 30]);
timeInds = find(ismember(selTimes,subTimes));
fracCut = 1/500;
fracLogic = denseVoxCounts(timeInds,:) > numVox*fracCut;
timeColorArray = othercolor('BuPu3',max(subTimes));

figure(1)
hold off
cutOffVoxInts = consMatLnB(denseVoxInts(timeInds,:,1),fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts(timeInds,:),fracLogic);
plot(deltaRBins(1:(end-1))',cutOffVoxInts./cutOffVoxCounts*concFracMT,'LineWidth',2);
colororder(timeColorArray(subTimes,:));
title('MT')

figure(2)
hold off
cutOffVoxInts = consMatLnB(denseVoxInts(timeInds,:,2),fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts(timeInds,:),fracLogic);
plot(deltaRBins(1:(end-1))',cutOffVoxInts./cutOffVoxCounts*concFracK4,'LineWidth',2);
colororder(timeColorArray(subTimes,:));
title('K4')

% rescale intensities by total sampled intensity
% figure
% 
% % yyaxis right
% scaleInts = denseVoxInts.*sumInts;
% cutOffVoxInts = consMatLnB(scaleInts,fracLogic);
% cutOffVoxCounts = consMatLnB(denseVoxCounts,fracLogic);
% plot(deltaRBins(1:(end-1))',cutOffVoxInts./cutOffVoxCounts,'LineWidth',2);

%% Plot max rho over time
saveBool = 0;

% concFrac = 42/1670;
% chanInd = 1;
% yAx = '[MT] (\muM)';
% chanStr = 'MT';
% rFill = [.8 .8 .8];
% rBnd = [0 0 0];
% % % % % triFill = [.3 .2 .3];
% triFill = [.8 .2 .7];
% mrkSz = 50;
% mrkType = 'o';

concFrac = 290/315;
chanInd = 2;
yAx = '[Kif4a] (nM)';
chanStr = 'Kif4a';
rFill = [55 132 255]/255;
rBnd = [.1 .2 1];
% % % % triFill = [.3 .2 .3];
triFill = [.8 .2 .7];
mrkSz = 20;
mrkType = 'diamond';

subTimes = sort([14:4:42 30]);
% subTimes = sort([14:4:42 28]);
% subTimes = [18 22 26 28 30 32 36 42];
timeColorArray = othercolor('BuPu3',max(subTimes));
timeInds = find(ismember(selTimes,subTimes));
fracCut = 1/1000;
fracLogic = denseVoxCounts(:,:) > numVox*fracCut;

% For plotting r(rho_max), define axis limit
ryLim = [0 10];

legendCell = {};
for index = 1:numel(timeInds)
    currInd = timeInds(index);
    legendCell{index} = sprintf('%i minutes', (selTimes(currInd) - frameZero)*deltaT);
end

allRhos = denseVoxInts(:,:,chanInd)./denseVoxCounts(:,:);
cutOffRhos = consMatLnB(allRhos,fracLogic);

[maxRhos,maxInds] = max(cutOffRhos,[],2);
maxRs = deltaRBins(maxInds);

% Plot deltaR distributions with rho_max peaks highlighted
figure(1)
hold off
cutOffVoxInts = consMatLnB(denseVoxInts(:,:,chanInd),fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts(:,:),fracLogic);
plot(deltaRBins(1:(end-1))',cutOffVoxInts(timeInds,:)./cutOffVoxCounts(timeInds,:)*concFrac,'LineWidth',2);
colororder(timeColorArray(subTimes,:));
hold on
scatter(maxRs(timeInds),maxRhos(timeInds)*concFrac,...
    'MarkerFaceColor',[.8 .2 .7],'MarkerEdgeColor','black','Marker','^','SizeData',60)
box on
legend(legendCell);
xlabel('Distance to Perimeter (um)')
% ylabel('[Kif4a] (nM)')
ylabel(yAx)
set(gca,'FontSize',15)

% Plot rho_max over time, highlighting data from the time points above
figure(2)
hold off
scatter((selTimes-frameZero)*deltaT,maxRhos*concFrac,...
    'MarkerFaceColor',[.8 .8 .8],'MarkerEdgeColor','black','SizeData',30)
hold on
scatter((selTimes(timeInds)-frameZero)*deltaT,maxRhos(timeInds)*concFrac,...
    'MarkerFaceColor',[.8 .2 .7],'MarkerEdgeColor','black','Marker','^','SizeData',60)
box on
xlabel('Time (min)')
ylabel(yAx)
set(gca,'FontSize',15)

% Plot r(rho_max) over time, highlighting data from the time points above
figure(3)
hold off
scatter((selTimes-frameZero)*deltaT,maxRs,...
    'MarkerFaceColor',rFill,'MarkerEdgeColor',rBnd,'Marker',mrkType,'SizeData',mrkSz)
hold on
scatter((selTimes(timeInds)-frameZero)*deltaT,maxRs(timeInds),...
    'MarkerFaceColor',triFill,'MarkerEdgeColor',rBnd,'Marker','^','SizeData',mrkSz+20)
box on
xlabel('Time (min)')
ylabel('Distance From Center (\mum)')
set(gca,'FontSize',15)
ylim(ryLim);

if saveBool == 1
    saveas(figure(1),fullfile(saveDir,sprintf('%s_DeltaR_withPks.fig',chanStr)));
    saveas(figure(1),fullfile(saveDir,sprintf('%s_DeltaR_withPks.png',chanStr)));
    saveas(figure(1),fullfile(saveDir,sprintf('%s_DeltaR_withPks.svg',chanStr)));
    
    saveas(figure(2),fullfile(saveDir,sprintf('%s_PkRhos.fig',chanStr)));
    saveas(figure(2),fullfile(saveDir,sprintf('%s_PkRhos.png',chanStr)));
    saveas(figure(2),fullfile(saveDir,sprintf('%s_PkRhos.svg',chanStr)));

    saveas(figure(3),fullfile(saveDir,sprintf('%s_RofPkRhos.fig',chanStr)));
    saveas(figure(3),fullfile(saveDir,sprintf('%s_RofPkRhos.png',chanStr)));
    saveas(figure(3),fullfile(saveDir,sprintf('%s_RofPkRhos.svg',chanStr)));
else
    fprintf('Figures not saved \n')
end

%% Overlay r(rho_max) for both channels
saveBool = 1;
subTimes = sort([14:4:42 30]);
% subTimes = sort([14:4:42 28]);
% subTimes = [18 22 26 28 30 32 36 42];
timeColorArray = othercolor('BuPu3',max(subTimes));
timeInds = find(ismember(selTimes,subTimes));
fracCut = 1/1000;
fracLogic = denseVoxCounts(:,:) > numVox*fracCut;

% For plotting r(rho_max), define axis limit
ryLim = [0 10];
chanStr = 'OverlayMTK4';

% Channel 1
concFrac1 = 42/1670;
chanInd1 = 1;
rFill1 = [.8 .8 .8];
rBnd1 = [0 0 0];
% % % % triFill = [.3 .2 .3];
triFill1 = [.8 .2 .7];
mrkSz1 = 50;
mrkType1 = 'o';

% Channel 2
concFrac2 = 290/315;
chanInd2 = 2;
rFill2 = [55 132 255]/255;
rBnd2 = [.1 .2 1];
% % % % triFill = [.3 .2 .3];
triFill2 = [.8 .2 .7];
mrkSz2 = 20;
mrkType2 = 'diamond';

% Get maxRs
allRhos = denseVoxInts(:,:,chanInd1)./denseVoxCounts(:,:);
cutOffRhos = consMatLnB(allRhos,fracLogic);
[~,maxInds] = max(cutOffRhos,[],2);
maxRs1 = deltaRBins(maxInds);
allRhos = denseVoxInts(:,:,chanInd2)./denseVoxCounts(:,:);
cutOffRhos = consMatLnB(allRhos,fracLogic);
[~,maxInds] = max(cutOffRhos,[],2);
maxRs2 = deltaRBins(maxInds);

% Plot r(rho_max) over time, highlighting data from the time points above
figure(3)
hold off
% Channel 1
scatter((selTimes-frameZero)*deltaT,maxRs1,...
    'MarkerFaceColor',rFill1,'MarkerEdgeColor',rBnd1,'Marker',mrkType1,'SizeData',mrkSz1)
hold on
scatter((selTimes(timeInds)-frameZero)*deltaT,maxRs1(timeInds),...
    'MarkerFaceColor',triFill1,'MarkerEdgeColor',rBnd1,'Marker','^','SizeData',mrkSz1+20)
% Channel 2
scatter((selTimes-frameZero)*deltaT,maxRs2,...
    'MarkerFaceColor',rFill2,'MarkerEdgeColor',rBnd2,'Marker',mrkType2,'SizeData',mrkSz2)
hold on
scatter((selTimes(timeInds)-frameZero)*deltaT,maxRs2(timeInds),...
    'MarkerFaceColor',triFill2,'MarkerEdgeColor',rBnd2,'Marker','v','SizeData',mrkSz2+20)
box on
xlabel('Time (min)')
ylabel('Distance From Center (\mum)')
set(gca,'FontSize',15)
ylim(ryLim);

if saveBool == 1
    saveas(figure(3),fullfile(saveDir,sprintf('%s_RofPkRhos.fig',chanStr)));
    saveas(figure(3),fullfile(saveDir,sprintf('%s_RofPkRhos.png',chanStr)));
    saveas(figure(3),fullfile(saveDir,sprintf('%s_RofPkRhos.svg',chanStr)));
else
    fprintf('Figures not saved \n')
end