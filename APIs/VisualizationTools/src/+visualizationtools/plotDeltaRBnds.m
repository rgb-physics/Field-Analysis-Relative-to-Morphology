%% Takes in data calculated from blobDensityDeltaR_Blobs.m
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

%% Plot distributions
concFracMT = 42/1670;
concFracK4 = 290/315;
subTimes = sort([14:4:42 30]);
timeInds = find(ismember(selTimes,subTimes));
fracCut = 1/500;
fracLogic = denseVoxCounts(timeInds,:) > numVox*fracCut;

timeColorArray = othercolor('BuPu3',max(subTimes));


figure
cutOffVoxInts = consMatLnB(denseVoxInts(timeInds,:,1),fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts(timeInds,:),fracLogic);
plot(deltaRBins(1:(end-1))',cutOffVoxInts./cutOffVoxCounts*concFracMT,'LineWidth',2);
colororder(timeColorArray(subTimes,:));

figure
cutOffVoxInts = consMatLnB(denseVoxInts(timeInds,:,2),fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts(timeInds,:),fracLogic);
plot(deltaRBins(1:(end-1))',cutOffVoxInts./cutOffVoxCounts*concFracK4,'LineWidth',2);
colororder(timeColorArray(subTimes,:));

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

% concFrac = 290/315;
% chanInd = 2;
% yAx = '[Kif4a] (nM)';
% chanStr = 'Kif4a';

concFrac = 42/1670;
chanInd = 1;
yAx = '[MT] (\muM)';
chanStr = 'MT';

deltaT = 0.5;
frameZero = 34;
% subTimes = sort([14:4:42 28]);
subTimes = [18 22 26 28 30 32 36 42];
timeInds = find(ismember(selTimes,subTimes));
fracCut = 1/1000;
fracLogic = denseVoxCounts(:,:) > numVox*fracCut;

legendCell = {};
for index = 1:numel(subTimes)
    legendCell{index} = sprintf('%i minutes', (subTimes(index) - frameZero)*deltaT);
end


allRhos = denseVoxInts(:,:,chanInd)./denseVoxCounts(:,:);
cutOffRhos = consMatLnB(allRhos,fracLogic);

[maxRhos,maxInds] = max(cutOffRhos,[],2);
figure(1)
hold off
cutOffVoxInts = consMatLnB(denseVoxInts(:,:,chanInd),fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts(:,:),fracLogic);
plot(deltaRBins(1:(end-1))',cutOffVoxInts(timeInds,:)./cutOffVoxCounts(timeInds,:)*concFrac,'LineWidth',2);
colororder(timeColorArray(subTimes,:));
hold on
scatter(deltaRBins(maxInds(timeInds)),maxRhos(timeInds)*concFrac,...
    'MarkerFaceColor',[.8 .2 .7],'MarkerEdgeColor','black','Marker','^','SizeData',60)
box on
legend(legendCell);
xlabel('Distance to Perimeter (um)')
% ylabel('[Kif4a] (nM)')
ylabel(yAx)
set(gca,'FontSize',15)

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

if saveBool == 1
    saveas(figure(1),fullfile(saveDir,sprintf('%s_DeltaR_withPks.fig',chanStr)));
    saveas(figure(1),fullfile(saveDir,sprintf('%s_DeltaR_withPks.png',chanStr)));
    saveas(figure(1),fullfile(saveDir,sprintf('%s_DeltaR_withPks.svg',chanStr)));
    
    saveas(figure(2),fullfile(saveDir,sprintf('%s_PkRhos.fig',chanStr)));
    saveas(figure(2),fullfile(saveDir,sprintf('%s_PkRhos.png',chanStr)));
    saveas(figure(2),fullfile(saveDir,sprintf('%s_PkRhos.svg',chanStr)));
else
    fprintf('Figures not saved \n')
end

%% Visualize distribution of voxel counts over distances and time
figure
imagesc(denseVoxCounts);
xlabel('r (um)')
ylabel('Time (min)')
xticklabels({'-40','-20','0','20','40','60'})
set(gca,'FontSize',15)

%% Plot distributions after renormalizing density by total blob masses
% Renormalize intensities by summing the total intensity INSIDE objects
blobBnds = [-30 2];
binIndBnds = find(ismember(deltaRBins,blobBnds));
bndLogic = binIndBnds(1):binIndBnds(2);
massSums = sum(denseVoxInts(:,bndLogic),2);
msNorms = (massSums)/(max(massSums));
% msNorms = (massSums - min(massSums))/(max(massSums) - min(massSums));
% msNorms = (massSums - min(massSums))/(max(massSums) - min(massSums));
voxSums = sum(denseVoxCounts(:,bndLogic),2);

concFrac = 42/1670;
chanInd = 1;
yAx = '[MT] (\muM)';
chanStr = 'MT';
deltaT = 0.5;
frameZero = 34;
% subTimes = sort([14:4:42 28]);
subTimes = [ 26 28 30 32 36 42];
timeInds = find(ismember(selTimes,subTimes));
fracCut = 1/1000;
timeColorArray = othercolor('BuPu3',max(subTimes));

% Get valid densities
fracLogic = denseVoxCounts(:,:) > numVox*fracCut;
allRhos = denseVoxInts(:,:,chanInd)./denseVoxCounts(:,:);
cutOffRhos = consMatLnB(allRhos,fracLogic);
[maxRhos,maxInds] = max(cutOffRhos,[],2);

figure
% hold off
cutOffVoxInts = consMatLnB(denseVoxInts(:,:,chanInd),fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts(:,:),fracLogic);
rawRhos = cutOffVoxInts./cutOffVoxCounts;
intScaledRhos = rawRhos./msNorms;
plot(deltaRBins(1:(end-1))',intScaledRhos(timeInds,:),'LineWidth',2);
colororder(timeColorArray(subTimes,:));
title(sprintf('Bounds %i to %i',blobBnds(1),blobBnds(2)))

figure
hold off
yyaxis left
plot((selTimes-frameZero)*deltaT,msNorms)
ylabel('Normalized Mass in Blobs')
hold on
yyaxis right
scatter((selTimes-frameZero)*deltaT,maxRhos*concFrac,...
    'MarkerFaceColor',[.8 .8 .8],'MarkerEdgeColor','black','SizeData',30)
ylabel('[MT]_{max} (\muM)')
xlabel('Time (min)')
set(gca,'FontSize',15);
title(sprintf('Bounds %i to %i',blobBnds(1),blobBnds(2)))

%% 

figure
hold off
yyaxis left
scatter((selTimes-frameZero)*deltaT,maxRhos.*msNorms*concFrac,...
    'MarkerFaceColor',[.8 .8 .8],'MarkerEdgeColor','black','SizeData',30)
ylabel('Normalized Mass in Blobs')
xlim([-5 15])
hold on
yyaxis right
plot((selTimes-frameZero)*deltaT,msNorms)
ylabel('[MT]_{max} (\muM)')
xlabel('Time (min)')
set(gca,'FontSize',15);
title(sprintf('Bounds %i to %i',blobBnds(1),blobBnds(2)))
xlim([-5 15])
% scatter(deltaRBins(maxInds(timeInds)),maxRhos(timeInds)*concFrac,...
%     'MarkerFaceColor',[.8 .2 .7],'MarkerEdgeColor','black','Marker','^','SizeData',60)


% plot(deltaRBins(1:(end-1))',cutOffVoxInts./cutOffVoxCounts*concFracMT,'LineWidth',2);