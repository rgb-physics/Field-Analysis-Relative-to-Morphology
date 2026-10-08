function [] = generateBlobsFromH5Segs(h5Dir, h5NameForm, saveSuperDir, selectTimes, h5Chan, scaleFact, blobKernel, threshVal, rawDims, saveBlobTifs)
%GENERATEBLOBSFROMH5SEGS Generate structures of individual blob  objects
%from segmented h5 data. OLD; two channel
% Ran on 2024-05-14, but much older

% Instantiate storage structure
storeStruct = struct();

% Generate a kernel to  detect blobs using Ricker wavelet, then erosion
scaledKern = blobKernel*scaleFact;
scaleStrel = strel("sphere", max(scaledKern/2,1));

% Generate save directories
structSaveDir = fullfile(saveSuperDir,sprintf('Data Structures_scale%i_blob%i_thresh%d', scaleFact,blobKernel, threshVal));
tifSaveDir = fullfile(saveSuperDir, 'Blob Tifs');
dataNameForm = 'Time%06i_Blobs.tif';
mkdir(structSaveDir);
mkdir(tifSaveDir);

% Iterate over times
for tInd = 1:numel(selectTimes)

    currT = selectTimes(tInd);
    % Time keeper
    if mod(tInd,10) == 1
        fprintf("Currently analyzing file number: %i\n", currT);
    end

    % Load h5 segmentation
    currH5 = h5read(fullfile(h5Dir,sprintf(h5NameForm,currT)),'/exported_data');
    segData = permute(squeeze(currH5(h5Chan,:,:,:)),[2 1 3]);

    % Upscale using imsane functionality
    scaledSegs = imresize3(segData, rawDims);
    
    % Find blobs
    logMat = -LOG(scaledSegs, scaledKern);
    blobMat = imbinarize(logMat, max(graythresh(logMat),threshVal));
    erodedBlobs = imerode(blobMat,scaleStrel);
    logRemaining = consMatLnB(logMat, ~erodedBlobs);
    moreBlobs = imbinarize(logRemaining, max(threshVal, graythresh(logRemaining)));

    % Threshold segmentation after removing blobs to stitch on holes
    newBlobMat = imfill(imerode((moreBlobs | blobMat),scaleStrel),'holes');

    % % Get region properties
    [currCC, storeStruct] = blobMat2CCProps(logicMat,reqFields,storeStruct);
    storeStruct(tInd).KernSize = scaledKern/2;
    storeStruct(tInd).ThreshVal = graythresh(logMat);
    storeStruct(tInd).FrameNum = currT;

    % Save blob mats as tifs for viewing
    if saveBlobTifs == 1
        save3DTiff(uint16(newBlobMat), fullfile(tifSaveDir, ['BlobMat_' sprintf(dataNameForm, currT)]));
    end

    % Save object ID inds as comnnected components object
    save(fullfile(structSaveDir, sprintf('objIDs_T%06i.mat', currT)),"currCC",'-mat');

end
%% Save
save(fullfile(structSaveDir, 'storageStruct.mat'),"storeStruct",'-mat');

end

