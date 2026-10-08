%% This script gets intensity in regions separated by 2D sheets of protein
%Directory info
% structDir = '<redacted original absolute path>';
structDir = 'Session 25, Exp 5';
structNameForm = 'Time%06i_regionsStruct.mat';
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 25, Exp 5';
imgFile = 'Time%06i_acOpt.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 25, Exp 5';
saveNameForm = "Time%06i_intensityStruct.mat";
selectTimes = 1:100;
strelRad = 2;

%% Define strel object
if strelRad > 0
    strelObj = strel("sphere", strelRad);
end

%%
intTotals = zeros(1, numel(selectTimes));
intCents = intTotals; intOuts = intTotals; 
intLayers = intTotals; intErLayers = intTotals;

centVols = intTotals; outVols = intTotals; 
layerVols = intTotals; erLayerVols = intTotals;

%%

for timeInd = 1:numel(selectTimes)
%% Load data
currT = selectTimes(timeInd);
currStruct = load(fullfile(structDir, sprintf(structNameForm,currT)));
currTif = tiffreadVolume(fullfile(imgDir, sprintf(imgFile, currT)));

%% Find intensity of: image total, center regions, outter regions, MT layers, eroded MT layers

intTotals(timeInd) = sum(currTif(:));
intCents(timeInd) = sum(currTif(currStruct.outputStruct.center));
intOuts(timeInd) = sum(currTif(currStruct.outputStruct.botOut | currStruct.outputStruct.topOut));
intLayers(timeInd) = sum(currTif(currStruct.outputStruct.botInds | currStruct.outputStruct.topInds));

erodedInds = imerode(currStruct.outputStruct.botInds | currStruct.outputStruct.topInds, strelObj);
intErLayers(timeInd) = sum(currTif(erodedInds));

centVols(timeInd) = numel(find(currStruct.outputStruct.center == 1));
outVols(timeInd) = numel(find((currStruct.outputStruct.botOut | currStruct.outputStruct.topOut) == 1));
layerVols(timeInd) = numel(find((currStruct.outputStruct.botInds | currStruct.outputStruct.topInds) == 1));
erLayerVols(timeInd) = numel(find(erodedInds == 1));

% 
end

%%
figure
scatter(1:numel(intTotals), intCents, 'filled')
hold on
scatter(1:numel(intTotals), intOuts, 'filled')

figure
scatter(1:numel(intTotals), intCents./intTotals, 'filled')
hold on
scatter(1:numel(intTotals), intOuts./intTotals, 'filled')

figure
scatter(1:numel(intTotals), intCents./centVols, 'filled')
hold on
scatter(1:numel(intTotals), intOuts./outVols, 'filled')

figure
scatter(1:numel(intTotals), centVols, 'filled')
hold on
scatter(1:numel(intTotals), outVols, 'filled')

figure
scatter(1:numel(intTotals), (intCents./centVols)./intTotals, 'filled')
hold on
scatter(1:numel(intTotals), (intOuts./outVols)./intTotals, 'filled')