%% Returns density profiles as a function of distance over time
% Requires processed images and a mask from which to construct distance
% transforms and bin data as a function of distance from a surface of
% interest. 
% This code expects segmented blobs/granules from which to construct
% bounding shells; shells are constructed via guassian smoothing of the
% signed distance transform of the segmentations.
% Rémi Boros - 2026-06-19

% imgDirs = {'<redacted original absolute path>',...
imgDirs = {'Session 81, Exp 3',...
    % '<redacted original absolute path>'};
    'Session 81, Exp 3'};
imgNames = {'t%03i_illBleachCorr16bit_560.tif','t%03i_illBleachCorr16bit_488.tif'};
% blobDir = '<redacted original absolute path>';
blobDir = 'Session 81, Exp 3';
blobName = 'T%03i_trajIDs.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';

selTimes = 2:2:60;

imgVoxSize = [.3667 .3667 1.5];     % um/pix in each dimension
rStep = .5;                          % step size for binning in um
rBnds = [-30 30];                   % in um
deltaRBins = min(rBnds):rStep:max(rBnds);
% Factors for generating a smoothed boundary from blob segmentations
layerMean = 0;  layerWidth = 1; gKern = 2;

%% 
% instantiate storage matrices
denseVoxInts = zeros(numel(selTimes),numel(deltaRBins)-1,numel(imgNames));
denseIntSTDs = denseVoxInts;
denseVoxCounts = zeros(numel(selTimes),numel(deltaRBins)-1);
sumInts = zeros(numel(selTimes),numel(imgNames));

for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    % Load mask
    currMask = logical(tiffreadVolume(fullfile(blobDir,sprintf(blobName,currT))));
    % Scale factors for later calculation
    if tInd == 1
        imgName = imgNames{1};  imgDir = imgDirs{1};
        currImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
        maskVoxSize = size(currImg)./size(currMask).*imgVoxSize;
        scaleFact = maskVoxSize/rStep;      % Factor to rescale mask before constructing shells
        distScale = rStep;                  % scale of pixels in distance transform matrix
    end

    % Rescale blobs prior to generating boundaries
    rsMask = imresize3(currMask,round(size(currMask).*scaleFact),'nearest');
    % Generate smoothed blob surfaces
    tic
    rsSmthBlobs = returnSmoothBlobsBW(logical(rsMask),layerMean,layerWidth,gKern);
    toc
    % Generate signed distance transform, then bin indices
    rsDist = signedBWDist(rsSmthBlobs)*distScale;
    % Rescale again to image size
    distMap = imresize3(rsDist,size(currImg),'nearest');

    % Bin dense protein intensities by delta R in distMat
    [denseVoxCounts(tInd,:),~,binInds] = histcounts(distMap,deltaRBins);

    % Define all indices that are within distances of deltaRBin away from
    % the blob boundaries
    validDomain = (distMap >= min(deltaRBins)) & (distMap <= max(deltaRBins));

    % Iterate over image directories that use the current mask
    for index = 1:numel(imgNames)
        imgName = imgNames{index};   imgDir = imgDirs{index};
        currImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
        sumInts(tInd,index) = sum(currImg(validDomain),'all');
        % Iterate over layers a distance r from boundaries, bin intensities
        for rInd = 1:(numel(deltaRBins)-1)
            currVals = currImg(binInds == rInd);
            denseVoxInts(tInd,rInd,index) = sum(currVals,'all');
            denseIntSTDs(tInd,rInd,index) = std(currVals);
        end
    end

end
numVox = numel(currImg);
save(fullfile(saveDir,'metadata.mat'),'numVox','imgNames','imgDirs','selTimes',...
    'layerMean','layerWidth','gKern','rStep','imgVoxSize','distScale','deltaRBins');
save(fullfile(saveDir,'ints_vols_overDeltaR.mat'),'denseIntSTDs',...
    'denseVoxCounts','denseVoxInts','sumInts');
