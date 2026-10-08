% Take in h5 segmentations of droplets over time and detect object centers
% and volumes over time. Use Laplacian of gaussian convolution to determine
% drop surfaces over time
%% Data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 35, Exp 1';
% h5Dir = '<redacted original absolute path>';
h5Dir = 'Session 35, Exp 1';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 35, Exp 1';
% blobSaveDir = '<redacted original absolute path>';
blobSaveDir = 'Session 35, Exp 1';
dataNameForm = 'Time%06i_16bit.tif';
h5NameForm = 'Rescaled_Time%06i_acOpt_Probabilities Stage 2.h5';
selectTimes = 1:50;
h5Chan = 2;
scaleFact = 2;
blobKernel = 2;
threshVal = .0039;      %Set to zero if you have no preference on minimum threshold value
pixSize = 11*2/20;      %Pre-scaledown for Ilastik (og. image pixel size)
saveBlobTifs =  1;       %Boolean to save tifs of segmentation maps w/o blobs

%% Load data
currTif = tiffreadVolume(fullfile(dataDir,sprintf(dataNameForm,selectTimes(1))));
storeStruct = struct();

%% Generate a kernel to  detect blobs using Ricker wavelet, then erosion
scaledKern = blobKernel*scaleFact;
scaleStrel = strel("sphere", max(scaledKern/2,1));

%% Iterate over times
for currT = 1:numel(selectTimes)
    
    %% Time keeper
    if mod(currT,10) == 1
        fprintf("Currently analyzing file number: %i\n", selectTimes(currT));
    end

    %% Load h5
    currH5 = h5read(fullfile(h5Dir,sprintf(h5NameForm,selectTimes(currT))),'/exported_data');
    segData = permute(squeeze(currH5(h5Chan,:,:,:)),[2 1 3]);

    %% Upscale using imsane functionality
    scaledSegs = fastLinIntNDScale2(segData);   %Scaled by two
    if size(scaledSegs,1) ~= size(currTif,1)
        scaledSegs(size(currTif,1),:,:) = scaledSegs(size(currTif,1)-1,:,:);
    end
    if size(scaledSegs,2) ~= size(currTif,2)
        scaledSegs(:,size(currTif,2),:) = scaledSegs(:,size(currTif,2)-1,:);
    end
    
    %% Get volume distribution
    
    % Get blobs erosion (binarize ( negative ( laplacian of gaussian of segmentation) ) )
%     blobMat = imerode(imbinarize(-LOG(scaledSegs, scaledKern)), scaleStrel);
    logMat = -LOG(scaledSegs, scaledKern);
    blobMat = imbinarize(logMat, max(graythresh(logMat),threshVal));
    erodedBlobs = imerode(blobMat,scaleStrel);
    logRemaining = consMatLnB(logMat, ~erodedBlobs);
    moreBlobs = imbinarize(logRemaining, max(threshVal, graythresh(logRemaining)));
%     currProps = regionprops3(blobMat,'Centroid','Volume');

    % Threshold segmentation after removing blobs to stitch on holes
%     leftOverSegs = consMatLnB(logMat, ~blobMat);
%     leftOverInds = imbinarize(leftOverSegs, max(graythresh(leftOverSegs), threshVal));
    newBlobMat = imfill(imerode((moreBlobs | blobMat),scaleStrel),'holes');

    % Get region properties
    currProps = regionprops3(newBlobMat,'Centroid','Volume');

    % Store in structure
    storeStruct(currT).Vol = currProps.Volume;
    storeStruct(currT).Cens = currProps.Centroid;
    storeStruct(currT).PixSize = pixSize;
    storeStruct(currT).KernSize = scaledKern/2;
    storeStruct(currT).ThreshVal = graythresh(logMat);

    % Save blob mats as tifs for viewing
    if saveBlobTifs == 1
        tempBlobMat = consMatLnB(scaledSegs,~blobMat);
        save3DTiff(uint16((2^15)*tempBlobMat), fullfile(saveDir,['BlobMatSegs_' sprintf(dataNameForm, selectTimes(currT))]))
        save3DTiff(uint16(newBlobMat), fullfile(blobSaveDir, ['BlobMat_' sprintf(dataNameForm, selectTimes(currT))]));
    end

end
%% Save
save(fullfile(saveDir, sprintf('storageStruct_scaleFact%i_blobKern%i_threshVal%d.mat', scaleFact,blobKernel, threshVal)),"storeStruct",'-mat');

%% Remove objects below certain volumes before saving
threshVol = 200;
reducedStruct = storeStruct;
for currT = 1:numel(storeStruct)

    currVols = storeStruct(currT).Vol;
    mapMat = currVols > threshVol;
    reducedStruct(currT).Vol = currVols(mapMat);
    reducedStruct(currT).Cens = storeStruct(currT).Cens(mapMat,:);


end

%% Save reduced structure
temp = storeStruct;
storeStruct = reducedStruct;
save(fullfile(saveDir, sprintf('reducedStruct_scaleFact%i_blobKern%i_threshVal%d.mat', scaleFact,blobKernel, threshVal)),"storeStruct",'-mat');
storeStruct = temp;

