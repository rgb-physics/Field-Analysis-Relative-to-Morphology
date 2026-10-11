% Renamed from dilateErodeSegWeights.m to cleanSegsAndFindSheets.m.
% Moved from SegmentationTools cleanup to Workflows/sheets for later review.

%% Data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 25, Exp 5';
dataNameForm = 'Time000001_acOpt_Probabilities Stage 2.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 25, Exp 5';
saveNameForm = 'Time000001_dilErode_2stage_weights.tif';
cutOffVal = 100;

%% Load data
currData = tiffreadVolume(fullfile(dataDir, dataNameForm));

%% Create strel obj, dilate then erode
dilObj = strel('sphere',3);
erodeObj = strel('sphere',4);

outData = imerode(imdilate(currData,dilObj),erodeObj);

%% Piecewise threshold
nanData = double(currData); nanData(nanData == 0) = nan;
zSTD = std(nanData,0,3,"omitnan");

%% Identify top and bottom layers
BWDATA = imbinarize(double(currData),cutOffVal);
[~,~,zMat] = ndgrid(1:size(BWDATA,1), 1:size(BWDATA,2), 1:size(BWDATA,3));

% filledMat = zMat; filledMat(~BWDATA) = 0;
% centerZCoords = round(sum(filledMat,3)./sum(BWDATA,3));
% [xMat, yMat] = ndgrid(1:size(BWDATA,1), 1:size(BWDATA,2));
% centerInds = sub2ind(size(BWDATA),xMat(:),yMat(:),centerZCoords(:));

splitSlice = getCentralSlice(BWDATA);

[topLayer,botLayer,topLayerZs,botLayerZs] = returnTopBottom2DSheets(BWDATA);



