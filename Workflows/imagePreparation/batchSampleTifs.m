%% From .h5 files, generates tifs sampled as masks
% Data directory info
% h5Dir = '<redacted original absolute path>';
h5Dir = 'Session 45, Exp 3';
% ogDir = '<redacted original absolute path>';
ogDir = 'Session 45, Exp 3';
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 45, Exp 3';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 45, Exp 3';

h5Name = 'Time%06i_560_Probabilities Stage 2.h5';
imgName = 'Time%06i_560.tif';
saveName = imgName;
selectTimes = 1:80;

segThresh = .6;

mkdir(saveDir);

%% iterate through time
for tInd = 1:numel(selectTimes)

    currT = selectTimes(tInd);
    currImg = tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT)));
    currh5 = h5read(fullfile(h5Dir,sprintf(h5Name,currT)),'/exported_data');
    selSegs = permute(squeeze(currh5(chanNum,:,:,:)),[2 1 3]);

    currSub = consMatLnB(currImg, imbinarize(selSegs,segThresh));
    save3DTiff(currSub, fullfile(saveDir,sprintf(saveName,currT)));

end

%% get average intensity stats
totInt = zeros(numel(selectTimes),1);
meanInt = zeros(numel(selectTimes),1);
scaledMeanInt = meanInt;
for tInd = 1:numel(selectTimes)

    currT = selectTimes(tInd);
    currOg = tiffreadVolume(fullfile(ogDir,sprintf(imgName,currT)));
    currImg = tiffreadVolume(fullfile(saveDir,sprintf(saveName,currT)));

    totInt = sum(currImg(:));
    meanInt(tInd) = sum(currImg(:))/sum(logical(currImg(:)));
    scaledMeanInt(tInd) = meanInt(tInd)/sum(currOg(:));
end

