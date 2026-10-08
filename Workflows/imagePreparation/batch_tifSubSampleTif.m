%% Takes in two directories, one containing .tifs of base data and one containing thresholded data
% Returns base tifs subsampled at select values of thresholded data
% 2023/11/01
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 81, Exp 3';
% threshDir = '<redacted original absolute path>';
threshDir = 'Session 81, Exp 3';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';
baseName = 't%03i_illBleachCorr16bit_560.tif';
threshName = 'FILLED_E3_BlobMat_t%03i.tif';
saveName = ['Subsampled_'  baseName];

timeRange = 45:2:60;
selThreshVals = 1:200000;
imgVoxSize = [0.3667 0.3667 1.5];
% Rescale final image?
scaleVec = [1 1 1];
% scaleVec = [2 2 0.5];
% Define scaling hierarchy
% scaleMode = 0;   % match logic dimensions to image dimensions 
scaleMode = 0;  % match image dimensions to logic dimensions
% Morphologically manipulate the mask? + dilation, - erosion, 0 unchanged
morphScale = 1;
% NOTE - erosion/dilation is restricted to increments of the largest image
% voxel dimension and is conducted on cubic voxels
invertBool = 0;

% Instantiate save directory
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end
% Instantiate morphological kernel, if requested
if abs(morphScale) > 0
    morphKern = strel('sphere',abs(morphScale));
end
%% iterate through time
for tInd = 1:numel(timeRange)

    currT = timeRange(tInd);
    currBaseName = fullfile(baseDir,sprintf(baseName,currT));
    currThreshName = fullfile(threshDir, sprintf(threshName,currT));
% Load data
    if isfile(currBaseName) && isfile(currThreshName)
        currBase = (tiffreadVolume(currBaseName));
        currThresh = double(tiffreadVolume(currThreshName));
    else
        continue
    end
    if tInd == 1
        imgSize = size(currBase);
        logSize = size(currThresh);
        szRatio = imgSize./logSize;
        logVoxSize = szRatio.*imgVoxSize;
        voxCubeRatio = imgVoxSize/max(imgVoxSize);
        logicScale = szRatio.*voxCubeRatio;
    end
% Generate logic matrix for subsmapling
    logicMat = ismember(currThresh,selThreshVals);
    morphMat = imresize3(logicMat,round(logSize./logVoxSize),'nearest');
    % morphMat = imresize3(logicMat,round(logSize.*logicScale),'nearest');
% Morphological pre-processing - the logic matrix must have cubic voxels!
    if morphScale > 0
        morphMat = imdilate(morphMat,morphKern);
    elseif morphScale < 0
        morphMat = imerode(morphMat,morphKern);
    end
% Prepare matrices for processing
    if scaleMode == 0
        procBase = imresize3(currBase,logSize);
        procLogic = morphMat;
    elseif scaleMode == 1
        procBase = currBase;
        procLogic = imresize3(morphMat,imgSize,'nearest');
    end
% Invert logic, if requested
    if invertBool == 1
        procLogic = ~procLogic;
    end
% Subsample and rescale
    currSubSamp = consMatLnB(procBase,procLogic);
    saveMat = imresize3(currSubSamp, size(currSubSamp).*scaleVec,'nearest');
% Save matrix as .tif
    save3DTiff(saveMat,fullfile(saveDir,sprintf(saveName,currT)));

end

save('metadata.m','morphScale','scaleVec','')
