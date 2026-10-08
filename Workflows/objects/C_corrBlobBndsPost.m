% Takes in directory of ID-ed blob .tifs, smooths blob surfaces by filling
% holes on FOV peripheries and subsequently smoothing boundaries

% ogDir = '<redacted original absolute path>';
ogDir = 'Session 81, Exp 3';
ogName = 'T%03i_trajIDs.tif';
% outDir =  '<redacted original absolute path>';
outDir =  'Session 81, Exp 3';
outName = ogName;

if ~exist(outDir,'dir')
    mkdir(outDir)
end

selTimes = 1:100;

% Fill blobs at the boundaries beginning at T = fillStart (frame)
fillStart = 35;
fillDims = 0:2;

% Smooth blob boundaries
layerMean = 0;          % Center of the new boundary wrt original boundary (pixels)
layerWidth = 0;         % Distance away from new boundary wrt new center (pixels)
gKern = 2;              % Used for smoothing
calcSpeed = 'slow';     % 'fast' smooths in one step, may run into issues with overlaps
                        % 'slow' smooths each object independently, then combines
preScale = gKern;           % Scale each image before smoothing
postScale = 1;        % Scale each image after smoothing, before saving

% Preserve IDS?
IDBool = 0;

%% Iterate over time

for tInd = 1:numel(selTimes)
% Load
    currT = selTimes(tInd);
    currTif = double(tiffreadVolume(fullfile(ogDir,sprintf(ogName,currT))));
    bwMat = currTif > 0;
    fillMat = currTif;
% Fill
    % Check that data should be filled based on frame number
    if currT >= fillStart
        % Binarize image, then fill binarized image
        bwMat = flatFill3D(bwMat,fillDims);
        if IDBool == 1
            labFilled = bwlabeln(bwMat);
            % Iterate over each object in the filled image, then reassign og. IDs
            unqIDs = unique(labFilled);
            for index = 1:numel(unqIDs)
                currInd = unqIDs(index);
                if currInd == 0
                    continue
                else
                    filledLogic = labFilled == currInd;
                    oldID = max(currTif(filledLogic));
                    fillMat(filledLogic) = oldID;
                end
            end
        elseif IDBool == 0
            fillMat = bwMat;
        end
    end
% Smooth object boundaries
    fillMat = imresize3(fillMat,size(fillMat).*preScale,'nearest');
    tic
    if IDBool == 1
        smthMat = returnSmoothBlobsIDed(fillMat,layerMean,layerWidth,gKern,calcSpeed);
    elseif IDBool == 0
        smthMat = returnSmoothBlobsBW(fillMat,layerMean,layerWidth,gKern)*255;
    end
    toc
    outMat = imresize3(smthMat,size(smthMat).*postScale,'nearest');

% Save
    save3DTiff(uint16(outMat),fullfile(outDir,sprintf(outName,currT)));

end



