% Takes in labeled objects in a tif, returns only objects that do not touch
% the edges of the frame
% For blobs


% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 3';
dataName = 'BlobMat_t%03i_illBleachCorr16bit.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';
saveName = 'T%03i_noEdges.tif';

selTimes = 1:50;
edgeLen = 5;
ghostObjVal = 1;

%% Iterate over time, do the thing

for tInd = 1:numel(selTimes)
    % Load
    currT = selTimes(tInd);
    currImg = tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT)));
    % Get invalid indices
    temp = bwlabeln(currImg);
    imgBorder = ~logical(padarray(ones(size(currImg)-2*edgeLen),[1 1 1]*edgeLen));
    removeInds = unique(temp(imgBorder));
    removeMat = ismember(temp,removeInds);
    % Reconstruct matrix
    outMat = consMatLnB(currImg,~removeMat) + consMatLnB(min(currImg,1),removeMat)*ghostObjVal;
    % Save
    save3DTiff(outMat,fullfile(saveDir,sprintf(saveName,currT)));
end

