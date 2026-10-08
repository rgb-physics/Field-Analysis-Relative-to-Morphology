%% Used to generate smoothed blob segmentations for isolated blob objects
% Isolated blob object is inputted as a logical tif; segmentations inputted
% as an h5
% Rémi Boros - 2024-05-29

%% Directory info
% h5Dir = '<redacted original absolute path>';
h5Dir = 'Session 87, Exp 5';
% isoBlobDir = '<redacted original absolute path>';
isoBlobDir = 'Session 81, Exp 3';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';
h5Name = 't%03i_illCorr8bit_560_Probabilities Stage 2.h5';
isoBlobName = 't%03i_touchingBlobs.tif';
saveName = 't%03i_touchingBlobs_segs.tif';

% Parameters
selectTimes = 1:200;
h5Chans = 1:3;
outInOnChans = [1 3 2];
denseThresh = 0.4;

%% Load, threshold, subsample, save

for tInd = 1:numel(selectTimes)

    currT = selectTimes(tInd);
    % Load
    currH5Name = fullfile(h5Dir,sprintf(h5Name,currT));
    currIsoName = fullfile(isoBlobDir,sprintf(isoBlobName,currT));
    if isfile(currH5Name) && isfile(currIsoName)
        currH5 = loadH5(currH5Name,'/exported_data',h5Chans);
        currLogic = logical(tiffreadVolume(currIsoName));
    else
        continue
    end
    % Split channels
    [cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(currH5,outInOnChans,denseThresh,1,1);
    % Subsample
    isoOutMat = consMatLnB(cleanIns,currLogic)*2 + consMatLnB(cleanOns,currLogic);
    % Save
    save3DTiff(uint8(isoOutMat),fullfile(saveDir,sprintf(saveName,currT)));


end
