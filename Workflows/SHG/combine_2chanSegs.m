%% convert series of xy-channels tifs into xyz for each channel
% 2024-10-02 Rémi Boros
% dataDir = '<redacted original absolute path>';
dataDir = '';
dataName = 'ZSlice4_SHG-1%04i_Probabilities.tif';
% saveDir = '<redacted original absolute path>';
saveDir = '';
saveName = 'combinedSegs_channel%i.tif';

selTimes = 0:75;

%% Load
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    currTif = tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT)));

    if tInd == 1
        imgSize = size(currTif);
        imgSize(3) = numel(selTimes);
        storeMat = zeros(imgSize);
    end
    storeMat(:,:,tInd,:) = currTif;
end

%% Save
for chanInd = 1:imgSize(4)
    save3DTiff(storeMat(:,:,:,chanInd),fullfile(saveDir,sprintf(saveName,chanInd)));
end