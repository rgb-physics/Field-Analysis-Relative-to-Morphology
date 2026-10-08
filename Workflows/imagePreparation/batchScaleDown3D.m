%% Data dir
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';

dataName = 't%03i_illBleachCorr16bit_560.tif';
saveName = dataName;

selectTimes = 15:25;

scaleFact = [1 1 1.5/1.1];

%% Iterate
mkdir(saveDir);
for tInd = 1:numel(selectTimes)

    currT = selectTimes(tInd);
    currTif = tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT)));

    save3DTiff(imresize3(currTif,round(size(currTif).*scaleFact)), fullfile(saveDir,sprintf(saveName,currT)));

end
