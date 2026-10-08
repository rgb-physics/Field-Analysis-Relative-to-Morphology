%% Quick and dirty image correction for correcting images with gauss blurred kernel
% homeDir = '<redacted original absolute path>';
homeDir = 'Session 45, Exp 3';
rawDir = fullfile(homeDir,'Raw Tifs');
saveDir = fullfile(homeDir,'4.5 Sparse Channel Illumination Corrected 8bit - Full');
rawName = 'Time%06i_raw647.tif';
saveName = 'Time%06i_gcorrCrop647.tif';

selectTimes = 1:40;
scaleFacts = [1 1 1];
gKern = 7;
bitRescale = 10000;
cutOffs8bit = bitRescale*[.6, 2.6];
cropCorner = [19 29 1];
winSize = [783 770 75];

%% Crop, Rescale, Gauss Corr
mkdir(saveDir);
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    % Load
    currTif = double(tiffreadVolume(fullfile(rawDir,sprintf(rawName,currT))));
    % Crop
    currCrop = cropTiffSave(currTif, cropCorner, winSize, 0);
    % Scale
    currScale = imresize3(currCrop, size(currCrop).*scaleFacts);
    if tInd == 1
        int1 = sum(currScale(:));
    end
    % Gauss Corr
    bgCorr = imgaussfilt(currScale,gKern);  % each 2D layer rather than 3D
    save3DTiff(uint8(currScale./bgCorr*100), fullfile(saveDir, sprintf(saveName,currT)));
end
