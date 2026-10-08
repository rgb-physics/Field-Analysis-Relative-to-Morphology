%% This script assumes sheets have already been segmented and returns the profile of MTs in segmented pixels along z
% segDir = '<redacted original absolute path>';
segDir = 'Session 25, Exp 5';
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 25, Exp 5';
segName = 'Time000040_regionsStruct.mat';
dataName = 'Time000040_16bit.tif';
rowRange = 170;
colRange = 110:240;
depthRange = 1:85;
voxelSize = 11*4/60;

%% Load data
currTif = tiffreadVolume(fullfile(dataDir, dataName));
currSeg = load(fullfile(segDir, segName));
interfaces = currSeg.outputStruct.botInds | currSeg.outputStruct.topInds;
[selRows, selCols, selDepths] = ndgrid(rowRange, colRange, depthRange);
selInds = sub2ind(size(currTif), selRows(:), selCols(:), selDepths(:));

%% Generate selected region
selData = squeeze(reshape( currTif(selInds), numel(rowRange), numel(colRange), numel(depthRange)))';
selInts = squeeze(reshape( interfaces(selInds), numel(rowRange), numel(colRange), numel(depthRange)))';
botInds = consMatLnB(cumsum(selInts,1), selInts);
topInds = consMatLnB(cumsum(selInts,1,'reverse'), selInts);
[~,maxInds] = max(botInds, [], 1);
[~,boundInds] = max(topInds, [], 1);

%% Determine required padding
midPlane = ceil(numel(depthRange)/2);
shiftDists = maxInds - midPlane;
padVal = max( abs(shiftDists));

%% Pad matrix
padMat = [zeros(padVal,numel(colRange)); selData; zeros(padVal,numel(colRange))];

%% Shift each column
shiftedMat = padMat;
for index = 1:numel(colRange)

    shiftedMat(:,index) = circshift(padMat(:,index),-shiftDists(index));

end

%% Mean vals
meanVals = flipud(mean(shiftedMat,2));

%% Height boundaries
zBounds = 67:105;
selectVals = meanVals(zBounds);
shiftedVals = selectVals - min(selectVals);
scaledVals = shiftedVals/sum(shiftedVals);

% scatter(voxelSize*(1:numel(zBounds)),scaledVals);
meanThickness = sum((voxelSize*(1:numel(zBounds)).*scaledVals'))/sum(scaledVals);
scatter(voxelSize*(1:numel(zBounds)),scaledVals,'filled');
set(gca,'FontSize',15)
xlabel('Layer Thickness (um)')
ylabel('Fraction (normalized)')
% legend(sprintf('Mean Val: %.02dum',meanThickness))
% legend(sprintf('<Thickness> %dum'),14.2)