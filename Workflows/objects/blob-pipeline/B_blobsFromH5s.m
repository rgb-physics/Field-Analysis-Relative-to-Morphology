%% Analyze and prepare blobs from h5 data for drops
% Take in .h5 segmentations from Ilastik and generate
    % storeStruct:  a structure that contains Volume, Centroid, KernelSize
    %               and Thresholding information
    % objIDs:       a series of structure containing the indices of all
    %               objects detected in each frame
    % edited: 2024-05-14

%% Load directory info
% h5Dir = '<redacted original absolute path>';
h5Dir = 'Session 88';
h5NameForm = 't%03i_illCorr8bit_560_E5_Probabilities Stage 2.h5';
% saveSuperDir = '<redacted original absolute path>';
saveSuperDir = 'Session 88';
saveNameForm = 'E5_BlobMat_t%03i.tif';

%% Define variables
% Input variables
selectTimes = 1:100;
h5Chans = [2 3];
saveBlobTifs = 1;
labelnBool = 1;
% ccFields = {'Centroid','Area','PixelIdxList','MajorAxisLength'};
ccFields = {'Centroid','Volume','VoxelIdxList','PrincipalAxisLength'};

% Thresholding method - 1 is basic binarization, 2 is ricker wavelet
threshMethod = 1;
threshVal = 0.6;        % for basic
scaleFact = 1;          % for ricker
blobKernel = 1;         % for ricker
scaledKern = blobKernel*scaleFact;

histMode = 0;
binNum = 100;

% fileNames = dir(fullfile())

%% Extract blobs from h5 files
storeStruct = struct();
for tInd = 1:numel(selectTimes)
    % Load
    currT = selectTimes(tInd);
    currPath = fullfile(h5Dir,sprintf(h5NameForm,currT));
    if ~exist(currPath,'file')
        continue
    end
    currH5 = double(loadH5(currPath,'/exported_data',h5Chans));
    % Compact channels
    H53D = sum(currH5,4);
    if histMode == 1
        if tInd == 1
            figure
        end
        histogram(H53D(:),binNum);
        hold on
        continue
    end
    % Threshold
    if threshMethod == 1
        % Get blobs from thresholding
        blobMat = sum(imbinarize3_4D(H53D,threshVal),4);
    elseif threshMethod == 2
        % Use Ricker wavelet to find blobs
        logMat = -LOG(H53D, scaledKern);
        blobMat = imbinarize(logMat, max(graythresh(logMat),std(logMat(:))));
        blobMat = sidesHoleFill(blobMat);
    end
    % Save blob mats as tifs for viewing
    if saveBlobTifs == 1
        if tInd == 1 && ~exist(fullfile(saveSuperDir,'Blob Tifs'),'dir')
            mkdir(fullfile(saveSuperDir,'Blob Tifs'));
        end
        if labelnBool == 1
            saveMat = bwlabeln(blobMat);
        else
            saveMat = blobMat;      
        end
        if numel(size(saveMat)) == 2
            saveMat = saveMat';
        end
        save3DTiff(uint16(saveMat), fullfile(fullfile(saveSuperDir,'Blob Tifs'), [sprintf(saveNameForm, currT)]));
    end
    
    % % Get region properties
    [currCC, storeStruct] = blobMat2CCProps(blobMat,ccFields,storeStruct);
    storeStruct(tInd).KernSize = scaledKern;
    storeStruct(tInd).FrameNum = currT;
    
    % Save object ID inds as comnnected components object
    if tInd == 1 && ~exist(fullfile(saveSuperDir,'CC Data'),'dir')
        mkdir(fullfile(saveSuperDir,'CC Data'));
    end
    save(fullfile(fullfile(saveSuperDir,'CC Data'), sprintf('objIDs_T%06i.mat', currT)),"currCC",'-mat');
end
segMatSize = size(H53D);
% Save
save(fullfile(fullfile(saveSuperDir,'CC Data'), 'storageStruct.mat'),"storeStruct","segMatSize",'-mat');

%% Early time dirt filtering





