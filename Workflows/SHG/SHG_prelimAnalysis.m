%% Estimates polarity fields for one of Rémi's and one of Quang's data sets

% Input the "super" directory of "Preliminary Analysis 2024-03-04"
% dataDir = '<redacted original absolute path>';
dataDir = '';
rData = '';

mtName = 'ZSlice5_MTs.tif';
shgName = 'ZSlice5_SHG.tif';

%% Remi Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Variables selected for Rémi data set
segNameHi = 'ZSlice5_SHG_Probabilities_HI.tif';          % Expected 8bit 0-255
segNameLo = 'ZSlice5_SHG_Probabilities_LO.tif';          % Expected 8bit 0-255
fullRDir = fullfile(dataDir,rData);
noiseVal = 10;      % approximate std of ints in regions of low/no polarity
bgChan = 1; hiPolChan = 1;
gSmooth = 1;
smoothKern = 2;
segThreshHi = 0.92*255;    segThreshLo = 0.92*255;
pDeg = 10;
sampleT = 52;
selT = 1:75;
highPolarVal = 1;       % Try 0.7 and compare
saveName = 'polarizationData_T52Sample_HiPol1p0_CenterMTs';

% Load Rémi data sets
mtMat = double(tiffreadVolume(fullfile(fullRDir,mtName)));
shgMat = double(tiffreadVolume(fullfile(fullRDir,shgName)));
segMatHi = double(tiffreadVolume(fullfile(fullRDir,segNameHi)));
segMatLo = double(tiffreadVolume(fullfile(fullRDir,segNameLo)));

selSHG = shgMat(:,:,sampleT);
selSegHi = segMatHi(:,:,sampleT,:);
selSegLo = segMatLo(:,:,sampleT,:);

% Shift intensities by noise
shiftMTs = max(1,mtMat - noiseVal);

% Define density field to use
densityField = shiftMTs;
if gSmooth == 1
    densityField = imgaussfilt(densityField,smoothKern);
end

selField = densityField(:,:,sampleT);

%% 

% SHIFT SHG by "SHG noise" (std)

% Calculate A and B
% Define logic matrices for calculating A and B
hiSHGMask = imbinarize(selSegHi(:,:,:,hiPolChan),segThreshHi);
% hiSHGMask = imbinarize(segMat(:,:,:,hiPolChan),segThreshHi);
% loSHGMask = imbinarize(segMat(:,:,:,bgChan),segThreshLo);
% Alternative low SHG mask, gives similar results
% loSHGMask = false(size(hiSHGMask)); loSHGMask(1:20,:) = 1; 
loSHGMask = imbinarize(selSegLo,segThreshLo);

% Sub-sample using logic matrices
subSHGHi = consMatLnB(selSHG,hiSHGMask);
subMTsHi = consMatLnB(selField,hiSHGMask);
subSHGLo = consMatLnB(selSHG,loSHGMask);
subMTsLo = consMatLnB(selField,loSHGMask);
% subSHGHi = consMatLnB(shgMat,hiSHGMask);
% subMTsHi = consMatLnB(densityField,hiSHGMask);
% subSHGLo = consMatLnB(shgMat,loSHGMask);
% subMTsLo = consMatLnB(densityField,loSHGMask);

% Calculate B, assuming 0 polarity in loSHGMask
% Try averaging selected pixels, THEN calculate B
BMat = consMatLnB(subSHGLo./subMTsLo,loSHGMask);
BMat(isnan(BMat)) = 0;
meanB = mean(BMat(BMat>0));
medianB = median(BMat(BMat>0));
stdB = std(BMat(BMat>0));

% Calculate A, assuming polarity 1 in hiSHGMask
% Try averaging selected pixels, THEN calculate A
AMat = consMatLnB( (subSHGHi - medianB*subMTsHi)./(subMTsHi.^2 * highPolarVal^2),hiSHGMask);
AMat(isnan(AMat)) = 0;
meanA = mean(AMat(AMat>0));
medianA = median(AMat(AMat>0));
stdA = std(AMat(AMat>0));

%% Calculate Polarity using A and B
% tempDir = '';
% mtMat = double(tiffreadVolume(fullfile(tempDir,'T320000.tif')));
% shgMat = double(tiffreadVolume(fullfile(tempDir,'T320001.tif')));
% densityField = max(1,mtMat - 6);

selA = medianA;   selB = medianB;
polMat = sqrt( (shgMat - selB*densityField)./(selA*densityField.^2) );
complexInds = (shgMat - selB*densityField) < 0;
polMat(isnan(polMat) | complexInds) = 0;

%% Plot the fields
% close all
selPol = polMat(:,:,sampleT);
figure
imagesc(selField);
title('Remi - MT intensity')
colorbar
figure
imagesc(selSHG);
title('Remi - SHG Signal')
colorbar
figure
imagesc(selPol);
clim([0 1])
colorbar
title(sprintf('Polarity Signal with A = %d B = %d',medianA,medianB))

%% Plot the fields 3D
% close all
figure
orthosliceViewer(densityField);
title('Remi - MT intensity')
figure
orthosliceViewer(shgMat);
title('Remi - SHG Signal')
figure
orthosliceViewer(polMat);
clim([0 2])
colorbar
title(sprintf('Polarity Signal with A = %d B = %d',medianA,medianB))

%% Save
save(fullfile(dataDir,[saveName '.mat']),'selA','selB','polMat','sampleT','highPolarVal')
save3DTiff(uint16(polMat*100),fullfile(dataDir,[saveName '.tif']))

%% Quang data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The idea here: load in density and shg data along with a coarse
% segmentation from Ilastik that distinguishes high and low density MT
% domains. Crop these such that only the interior-exterior boundary of the
% aster remains in view. Using bwconncomp, identify the "object"
% corresponding to the aster exterior/arm, then isolate it from other
% smaller objects. Finally, use the distance transform to generate a
% scaling matrix that favors pixels near the interior-exterior interface
% before calculating A and B

noiseVal = 1.6;         % Quang data set 4

% Variables
perimSegName = 'TimeStack_MT_Ints_Probabilities.tiff';
segThresh = 0.5;
cropBoundsHi = 150:256;
cropRowsLo = 80:130;
cropColsLo = 1:30;
numBins = 50;

fullQDir = fullfile(dataDir,qData);

% Load the data
mtMat = double(tiffreadVolume(fullfile(fullQDir,mtName)));
shgMat = double(tiffreadVolume(fullfile(fullQDir,shgName)));
perimSegMat = double(tiffreadVolume(fullfile(fullQDir,perimSegName)));

% Crop data to isolate interface
cropMTs = mtMat(cropBoundsHi,:);
cropSHG = shgMat(cropBoundsHi,:);
cropSeg = perimSegMat(cropBoundsHi,:,:,:);

% Split segmentation into background and MTs
[mtInds,bgInds,bgCorrections] = h5toSmooth3Chans(cropSeg,[1 2 2],segThresh,1,1);
objs = bwconncomp(mtInds | bgCorrections);

% Get object sizes, then isolate largest object
objVols = cellIndSizes(objs.PixelIdxList',1);
largestObjIDs = find(objVols == max(objVols));
largestObjsInds = vertcat(objs.PixelIdxList{largestObjIDs});
largestObjsMat = logical(consMatLnB(ones(size(cropMTs)),largestObjsInds));

% Distance transform from boundary -> use to scale
distMat = distTransFromBoundary(largestObjsMat, ~largestObjsMat, false(size(largestObjsMat)), 1);
[~,~,binInds] = histcounts(distMat,numBins);
binInds = max(binInds,ceil(numBins/2)-1) - ceil(numBins/2) + 1;     % bin positive definite values of distance matrix
shiftScaleMat = - double(binInds <= 0);   % Shift portions of scaleMat below that are on interior of surface boundary from 1 to 0
scaleMat = 1./(max(1,binInds)) + shiftScaleMat;     %Scale by one over bin value, for more contributions near boundary and zero contrubitions in core

% Get a small region for the "low" matrices
cropMTsLow = mtMat(cropRowsLo, cropColsLo);
cropSHGLow = shgMat(cropRowsLo, cropColsLo);

% Use scalemat to approximate A and B
shiftMTsCrop = max(1,cropMTs - noiseVal);

currDensity = shiftMTsCrop;

subSHGLo = cropSHGLow;
subMTsLo = cropMTsLow;
subSHGHi = scaleMat.*cropSHG;
subMTsHi = scaleMat.*currDensity;

% Calculate B, assuming 0 polarity in loSHGMask
BMat = subSHGLo./subMTsLo;
BMat(isnan(BMat)) = 0;
meanB = mean(BMat(BMat>0));
medianB = median(BMat(BMat>0));
stdB = std(BMat(BMat>0));

% Calculate A, assuming polarity 1 in hiSHGMask
AMat = (subSHGHi - medianB*subMTsHi)./(subMTsHi.^2 * 1^2);
AMat(isnan(AMat)) = 0;
meanA = mean(AMat(AMat>0));
medianA = median(AMat(AMat>0));
stdA = std(AMat(AMat>0));

% Calculate Polarity using A and B
selA = medianA;   selB = medianB;
polMat = sqrt( (shgMat - selB*mtMat)./(selA*mtMat.^2) );
complexInds = (shgMat - selB*mtMat) < 0;
polMat(isnan(polMat) | complexInds) = 0;

%% Plot the fields
figure
imagesc(mtMat);
title('Quang - MT intensity')
figure
imagesc(shgMat);
title('Quang - SHG Signal')
figure
imagesc(polMat);
clim([0 1])
colorbar
title(sprintf('Polarity Signal with A = %d B = %d',medianA,medianB))
