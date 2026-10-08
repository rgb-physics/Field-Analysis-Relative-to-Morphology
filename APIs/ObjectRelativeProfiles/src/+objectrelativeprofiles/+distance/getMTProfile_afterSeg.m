%% This script assumes sheets have already been segmented and returns the profile of MTs in segmented pixels along z
% segDir = '<redacted original absolute path>';
segDir = 'Session 25, Exp 5';
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 25, Exp 5';
segNameForm = 'Time%0.6i_regionsStruct.mat';
dataNameForm = 'Time%0.6i_16bit.tif';
voxelSize = 11*4/60;
selectTimes = 1:100;

depthStruct = struct();
for index = 1:numel(selectTimes)
    %% Load data
    currTif = tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm,selectTimes(index))));
    currSeg = load(fullfile(segDir, sprintf(segNameForm,selectTimes(index))));
    
    %% Sample intensities
    topSurf = currSeg.outputStruct.topInds;
%     topSurfInts = consMatLnB(currTif, topSurf);
    
    %% Get edge indices
    depthInds = consMatLnB(cumsum(topSurf,3,'reverse'), topSurf);
    
    %% Look at mean intensities as function of distance from segmented edge nearest sample center
    meanVals = zeros(max(depthInds(:)),1);
    for currDepth = 1:max(depthInds(:))
        meanVals(currDepth) = mean(currTif(depthInds == currDepth));
    end
    
    %% Scatter
    depthStruct(index).meanVals = meanVals;
%     scatter((1:max(depthInds(:)))*voxelSize, meanVals,'filled')
%     hold on
end

%% Truncated matrix
truncMat = zeros(35,size(depthStruct,2));
for index = 1:size(truncMat,2)

    truncMat(:,index) = depthStruct(index).meanVals(1:35);

end
%% Generate normalization matrix
% maxVals = max(truncMat,[],2);
% maxMat = repmat(maxVals,[1 100]);
maxVals = max(truncMat,[],1);
maxMat = repmat(maxVals,[35 1]);

%% Normalize
normMat = truncMat./maxMat;

