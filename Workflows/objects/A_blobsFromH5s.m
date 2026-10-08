%% Analyze and prepare blobs from h5 data for drops
% Take in .h5 segmentations from Ilastik and generate
    % storeStruct:  a structure that contains Volume, Centroid, KernelSize
    %               and Thresholding information
    % objIDs:       a series of structure containing the indices of all
    %               objects detected in each frame
    % edited: 2024-05-14 - Rémi Boros

%% Load directory info

expInds = 3;
fillTimes = 26;

for index = 1:numel(expInds)
    expInd = expInds(index);
    
    % baseDir = '<redacted original absolute path>';
    baseDir = 'Session 81, Exp 3';
h5Dir = fullfile(baseDir,'4 Ilastik','3 Chan');
h5NameForm = 't%03i_illCorr8bit_560_Probabilities Stage 2.h5';
saveSuperDir = fullfile(baseDir,'5 Segmented Blobs - 2');
saveNameForm = 'FILLED_E%i_BlobMat_t%03i.tif';
    
%% Define variables
% Input variables
selectTimes = [13:20, 21:2:45, 46:60];
h5Chans = [2 3];
saveBlobTifs = 1;
labelnBool = 1;
% ccFields = {'Centroid','Area','PixelIdxList','MajorAxisLength'};
ccFields = {'Centroid','Volume','VoxelIdxList','PrincipalAxisLength'};

% Thresholding method - 1 is basic binarization, 2 uses smoothed distance
%                       transform to smooth edges
threshMethod = 2;
layerMean = 0;
layerWidth = 0;
gKern = 2;
calcSpeed = 'fast';

threshVal = 0.6;        % for basic
scaleFact = 1;          % for ricker
blobKernel = 1;         % for ricker
scaledKern = blobKernel*scaleFact;

histMode = 0;
binNum = 100;

% Blob Fill dimensions - xy=0, yz=1, xz=2
fillBool = 1;
fillDims = 0:2;
fillStart = fillTimes(index);

%% Extract blobs from h5 files
storeStruct = struct();
for tInd = 1:numel(selectTimes)
    % Load
    currT = selectTimes(tInd);
    currPath = fullfile(h5Dir,sprintf(h5NameForm,currT));
    % currPath = fullfile(h5Dir,sprintf(h5NameForm,currT,expInd));
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
    % Get blobs from thresholding
    blobMat = sum(imbinarize3_4D(H53D,threshVal),4);
    if threshMethod == 2
        % Use Ricker wavelet to find blobs
                % edited 2026-09-14: pre-threshold, then smooth using dist.
        blobMat = returnSmoothBlobsIDed(logical(blobMat),layerMean,layerWidth,gKern,calcSpeed);
    end
    % Fill blobs, if requested
    if (fillBool == 1) && (currT >= fillStart)
        blobMat = flatFill3D(blobMat,fillDims);
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
        save3DTiff(uint16(saveMat), ...
            fullfile(fullfile(saveSuperDir,'Blob Tifs'), sprintf(saveNameForm, expInd, currT)));
    end
    
    % % Get region properties
    [currCC, storeStruct] = blobMat2CCProps(blobMat,ccFields,storeStruct);
    storeStruct(tInd).KernSize = scaledKern;
    storeStruct(tInd).FrameNum = currT;
    
    % Save object ID inds as comnnected components object
    if tInd == 1 && ~exist(fullfile(saveSuperDir,'CC Data'),'dir')
        mkdir(fullfile(saveSuperDir,'CC Data'));
    end
    save(fullfile(fullfile(saveSuperDir,'CC Data'), sprintf('E%i_objIDs_T%06i.mat', expInd, currT)),"currCC",'-mat');
end
end
segMatSize = size(H53D);
% Save
% save(fullfile(fullfile(saveSuperDir,'CC Data'), 'storageStruct.mat'),"storeStruct","segMatSize",'-mat');

