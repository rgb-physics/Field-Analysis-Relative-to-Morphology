%% Calculates simple quantities like fraction occupied by blobs over time
% Take in tifs, get total volume/int quantities and statistics; optionally
% one can mask
% 2024-09-11 - Rémi Boros

% Data info
% segDir = '<redacted original absolute path>';
segDir = 'Session 87, Exp 5';
segName = 'BlobMat_t%03i.tif';
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 87, Exp 5';
imgName = 't%03i_illBleachCorr16bit_560.tif';
% maskDir = '<redacted original absolute path>';
maskDir = 'Session 81, Exp 3';
maskName = 'Time%06i_Probabilities_smoothbin.tif';

saveFileName = 'VolumeFracs_MTs_withMasksDil1.mat';

timeRange = 1:100;
imgPixSize = [11*2/60 11*2/60 0.7];
   
maskBool = 0;
dilateRad = 1;

%% From three channel segmentations (second pass)
allVols = zeros(1,numel(timeRange));  
maskInVols = allVols;   maskOutVols = allVols;
allInts = zeros(1,numel(timeRange));    
maskedIntsIn = allInts;     maskedIntsOut = allInts;
totalInts = zeros(1,numel(timeRange));

for tInd = 1:numel(timeRange)
    % Load segmentation and corresponding tif, if it exists
    currT = timeRange(tInd);
    currName = fullfile(segDir,sprintf(segName,currT));
    if isfile(currName)
        currTif = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
        currSeg = logical(tiffreadVolume(fullfile(segDir,sprintf(segName,currT))));
    else
        timeRange(tInd) = -1;
        continue
    end

    % Rescale segmentation before sub-sampling intensity
    binSeg = imresize3(currSeg,size(currTif),'nearest');

    % Load mask, if requested
    if maskBool == 1
    % Load mask, if it exists; else generate blank mask
        if isfile(fullfile(maskDir,sprintf(maskName,currT)))
            maskData = logical(tiffreadVolume(fullfile(maskDir,sprintf(maskName,currT))));
            if dilateRad > 0
                maskData = imdilate(maskData,strel('sphere',dilateRad));
            end
        else
            maskData = false(size(currTif));
        end
        % Rescale mask, if needed
        if sum(size(maskData)  == size(currTif)) ~= 3
            maskData = imresize3(maskData,size(currTif),'nearest');
        end
        % Split mask into in and outside of object portions
        maskInLogic = ~(binSeg & ~maskData) & binSeg;
        maskOutLogic = maskData & ~maskInLogic;
    else
        maskInLogic = false(size(binSeg));
        maskOutLogic = false(size(binSeg));
    end

    % Store averages
    allVols(tInd) = sum(binSeg,'all') - sum(maskInLogic,'all');
    maskInVols(tInd) = sum(maskInLogic,'all');
    maskOutVols(tInd) = sum(maskOutLogic,'all');
    maskedIntsIn(tInd) = sum(consMatLnB(currTif,maskInLogic),'all');
    maskedIntsOut(tInd) = sum(consMatLnB(currTif,maskOutLogic),'all');
    allInts(tInd) = sum(consMatLnB(currTif,binSeg),'all') - maskedIntsIn(tInd);
    totalInts(tInd) = sum(currTif,'all');

end
% Calculate segmented pixel size
segPixSize = imgPixSize.*size(currTif)./size(currSeg);

%% 
timeRange = timeRange(timeRange>-1);    allVols = allVols(:,timeRange);
% totalInts = totalInts(timeRange);    
allInts = allInts(:,timeRange);
totalPix = numel(currTif);
save(fullfile(segDir,saveFileName),'timeRange','allVols', 'maskInVols', 'maskOutVols',...
    'allInts','maskedIntsIn','maskedIntsOut','totalPix','totalInts','segPixSize','imgPixSize');

