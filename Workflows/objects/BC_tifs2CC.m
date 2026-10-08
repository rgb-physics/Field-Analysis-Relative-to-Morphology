%% Generate tracks from parsed blobs
% Takes in directory of blob tifs and generates connected componenent
% structures that can be used further along in this pipeline

% Dir info
% blobDir = '<redacted original absolute path>';
blobDir = 'Session 56, Exp 1';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 56, Exp 1';
blobNameForm = 'Time%06i_Probabilities_smoothbin.tif';

timeRange = 1:100;
reqFields = {'Volume','Centroid'};
validInts = [170 255];

%% Iterate and save
% Instantiate save directory
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end
% Iterate over each .tif
for tInd = 1:numel(timeRange)
    % Load current blob matrix
    currT = timeRange(tInd);
    fileName = fullfile(blobDir,sprintf(blobNameForm,currT));
    if ~isfile(fileName)
        continue
    end
    currBlobs = tiffreadVolume(fileName);
    % Get region properties of blobs in current matrix
    logicMat = ismember(currBlobs,validInts);
    [currCC, storeStruct] = blobMat2CCProps(logicMat,reqFields,storeStruct);
    storeStruct(tInd).KernSize = [];
    storeStruct(tInd).ThreshVal = validInts;
    storeStruct(tInd).FrameNum = currT;
    storeStruct(tInd).FileName = fileName;
    % Save 
    save(fullfile(saveDir, sprintf('objIDs_T%06i.mat', currT)),"currCC",'-mat');
end
save(fullfile(saveDir, 'storageStruct.mat'),"storeStruct",'-mat');
