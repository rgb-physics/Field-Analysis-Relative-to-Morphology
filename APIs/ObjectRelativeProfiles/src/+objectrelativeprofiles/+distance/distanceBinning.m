% Load data structures saved to distinguish objects over time. One object
% per time point. Generate an interface between any two objects, then
% calculate the signed distance transform of that interface. Negative
% points to interior of first listed object

% Load data
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 28, Exp 6';
dataName = 'SplitRegions_Time%06i.mat';     % Struct with fields corresponding to vectors of indices in separate objects
% fieldDir = '<redacted original absolute path>';
fieldDir = 'Session 28, Exp 6';
fieldName = 't%03i_illBleachCorr16bit.tif';

selectTimes = 150;
region1Parts = {1,2};
region2Parts = {5};
objMatSize = [381 387 180];
% Be sure that your object indices are defined in a space with cubic voxels!

deltaRBins = 100;       % Can be a scalar or vector

%% Iterate over time, bin
for tInd = 1:numel(selectTimes)
% Load data
    currT = selectTimes(tInd);
    currTif = tiffreadVolume(fullfile(fieldDir,sprintf(fieldName,currT)));
    imgSize = size(currTif);
    currStruct = load(fullfile(dataDir,sprintf(dataName,currT)));
    structName = fieldnames(currStruct);
    loadedStruct = currStruct.(structName{:});

% Generate objects from which to find an interface
    structFields = fieldnames(loadedStruct);
    indices1 = [];  indices2 = indices1;
    for objInd = 1:numel(region1Parts)
        currObj = region1Parts{objInd};
        indices1 = [indices1 loadedStruct.(structFields{currObj})'];
    end
    
    for objInd = 1:numel(region2Parts)
        currObj = region2Parts{objInd};
        indices2 = [indices2 loadedStruct.(structFields{currObj})'];
    end
    
    obj1 = consMatLnB(ones(objMatSize),indices1);
    obj2 = consMatLnB(ones(objMatSize),indices2);

% Generate the distance transform from the objects' interface
    % It is assumed that objects are defined in a space with cubic voxels
    distMat = imresize3(distTransFromBoundary(obj1, obj2, false(size(obj1)), 1),imgSize);

% Bin based on deltaR
    if tInd == 1
        [binCounts,binEdges,binInds] = histcounts(distMat,deltaRBins);
        voxCounts = zeros(numel(selectTimes),numel(binEdges)-1);
        fieldVals = voxCounts;
    end
    voxCounts(tInd,:) = binCounts;
    boundedDenseNorm = sum(currTif((distMat >= min(binEdges)) & (distMat <= max(binEdges))),'all');
    for rInd = 1:(numel(binEdges)-1)
        fieldVals(tInd,rInd) = sum(currTif(binInds == rInd),'all')/boundedDenseNorm;
    end
end

%% %%%%%%%%%%%%%%%%%%%%% Plot some things %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Plot objects and a selected level set
selectBin = 24;

figure
orthosliceViewer(imresize3(obj1 + 2*obj2,imgSize) + 3*(binInds == selectBin));

%% Plot field values over delta r
figure
plot(binEdges(1:end-1),fieldVals./voxCounts)




