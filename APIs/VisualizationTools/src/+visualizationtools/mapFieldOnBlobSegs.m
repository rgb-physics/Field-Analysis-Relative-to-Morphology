% Directory info

% blobDir = '<redacted original absolute path>';
blobDir = 'Session 35, Exp 1';
% fieldDir = '<redacted original absolute path>';
fieldDir = 'Session 35, Exp 1';
blobMatName = 'BlobMat_Time%06i_Blobs.tif';
fieldName = 'Time%06i_16bitcropped.tif';

% saveDir = '<redacted original absolute path>';
saveDir = 'Session 35, Exp 1';
saveName = 'Time%06i.tif';
selectTimes = 1:50;

%% save tifs
for tInd = 1:numel(selectTimes)

    currT = selectTimes(tInd);
    currField = tiffreadVolume(fullfile(fieldDir,sprintf(fieldName, selectTimes(tInd))));
    currLogic = tiffreadVolume(fullfile(blobDir, sprintf(blobMatName, selectTimes(tInd))));
    currThing = consMatLnB(currField, logical(currLogic));
   
    save3DTiff(uint16(currThing), fullfile(saveDir, sprintf(saveName,currT)));

end
