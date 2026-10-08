%% Take in tifs, return one tif stacked along z
% Rémi Boros - 2024-10-28


% dataDir = '<redacted original absolute path>';
dataDir = 'Session 12, Exp 4';
dataName = 'Time%06i.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 12, Exp 4';
saveName = 'stacked.tif';

selTimes = [0 11 16 22 26];

%% Iterate over time, load, and stack
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    currTif = tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT)));
    if tInd == 1
        tifSize = size(currTif);
        stackedMat = zeros(tifSize(1),tifSize(2),tifSize(3)*numel(selTimes));   
    end
    stackedMat(:,:,(1:tifSize(3)) + tifSize(3)*(tInd-1)+1) = currTif;

end

% Save the stacked tif
save3DTiff(uint16(stackedMat),fullfile(saveDir,saveName));
