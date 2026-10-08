%% Estimates polarity fields for one of Rémi's SHG data sets
% This version of the code samples data from several times/slices
% 2025-02-04
% Input the "super" directory of "Preliminary Analysis 2024-03-04"
% dataDir = '<redacted original absolute path>';
dataDir = '';
rData = '';

mtName = 'ZSlice5_MTs.tif';
shgName = 'ZSlice5_SHG.tif';

%% Remi Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Variables selected for Rémi data set
segNameHi = 'ZSlice5_SHG_Probabilities_HI.tif';          % Expected 8bit 0-255
segNameLo = 'ZSlice5_SHG_Probabilities_LO2.tif';          % Expected 8bit 0-255
fullRDir = fullfile(dataDir,rData);
bgVal = 0;      % approximate bg to shift from MT data
% Booleans: smooth MT/SHG fields before calculating A and B?
intSmooth = 1;
shgSmooth = 1;
smoothKern = 1;
segThreshHi = 0.92*255;    segThreshLo = 0.9*255;
pDeg = 10;
sampleT = 49:51;
selT = 1:75;
highPolarVal = 1;       % Try 0.7 and compare
scalarAB = 1;
saveName = 'polData_T52Ref_HiPol1p0_LOCenterSHG_ScalarAB';
% saveDir = '<redacted original absolute path>';
saveDir = '';

% Load Rémi data sets
mtMat = double(tiffreadVolume(fullfile(fullRDir,mtName)));
shgMat = double(tiffreadVolume(fullfile(fullRDir,shgName)));
segMatHi = double(tiffreadVolume(fullfile(fullRDir,segNameHi)));
segMatLo = double(tiffreadVolume(fullfile(fullRDir,segNameLo)));

% Shift intensities by noise
shiftMTs = max(1,mtMat - bgVal);

% Define density field to use
densityField = shiftMTs(:,:,selT);
if intSmooth == 1
    densityField = imgaussfilt(densityField,smoothKern);
end
intField = densityField(:,:,sampleT);

selSHG = shgMat(:,:,selT);
if shgSmooth == 1
    selSHG = imgaussfilt(selSHG,smoothKern);
end
shgField = selSHG(:,:,sampleT);

%% 
% Calculate A and B
% Define logic matrices for calculating A and B
hiSHGMask = imbinarize(segMatHi(:,:,sampleT),segThreshHi);
hiSHGMask2D = logical(max(hiSHGMask,[],3));
% Alternative low SHG mask, gives similar results
% loSHGMask = false(size(hiSHGMask)); loSHGMask(1:20,:,:) = 1; 
% loSHGMask2D = loSHGMask(:,:,1);
loSHGMask = imbinarize(segMatLo(:,:,sampleT),segThreshLo);
loSHGMask2D = logical(max(loSHGMask,[],3));

% Sample median along z
subSHGHi = median(consMatLnB(shgField,hiSHGMask),3);
subMTsHi = median(consMatLnB(intField,hiSHGMask),3);
subSHGLo = median(consMatLnB(shgField,loSHGMask),3);
subMTsLo = median(consMatLnB(intField,loSHGMask),3);

% Calculate scalar A, B using mean SHG/Ints?
if scalarAB == 1
    meanSHGHi = nonZeroMean(subSHGHi(:),1);
    meanMTsHi = nonZeroMean(subMTsHi(:),1);
    meanSHGLo = nonZeroMean(subSHGLo(:),1);
    meanMTsLo = nonZeroMean(subMTsLo(:),1);
    
    meanB = meanSHGLo/meanMTsLo;
    meanA = (meanSHGHi - meanB*meanMTsHi)./(meanMTsHi.^2 * highPolarVal^2);

    selA = meanA;   selB = meanB;
else
    % Calculate B, assuming 0 polarity in loSHGMask
    % Try averaging selected pixels, THEN calculate B
    BMat = consMatLnB(subSHGLo./subMTsLo,loSHGMask2D);
    BMat(isnan(BMat)) = 0;
    meanB = mean(BMat(BMat>0));
    medianB = median(BMat(BMat>0));
    stdB = std(BMat(BMat>0));
    
    % Calculate A, assuming polarity 1 in hiSHGMask
    % Try averaging selected pixels, THEN calculate A
    AMat = consMatLnB( (subSHGHi - medianB*subMTsHi)./(subMTsHi.^2 * highPolarVal^2),hiSHGMask2D);
    AMat(isnan(AMat)) = 0;
    meanA = mean(AMat(AMat>0));
    medianA = median(AMat(AMat>0));
    stdA = std(AMat(AMat>0));
    
    selA = medianA;   selB = medianB;
end

%% Calculate Polarity using A and B
% polMat = sqrt( (shgMat - selB*mtMat)./(selA*mtMat.^2) );
% complexInds = (shgMat - selB*mtMat) < 0;
polMat = sqrt( (selSHG - selB*densityField)./(selA*densityField.^2) );
complexInds = (selSHG - selB*densityField) < 0;
polMat(isnan(polMat) | complexInds | isinf(polMat)) = 0;

%% Plot the fields
% close all
testT = sampleT(1);
selPol = polMat(:,:,testT);
figure
imagesc(intField(:,:,1));
title('Remi - MT intensity')
colorbar
figure
imagesc(shgField(:,:,1));
title('Remi - SHG Signal')
colorbar
figure
imagesc(selPol);
clim([0 1])
colorbar
title(sprintf('Polarity Signal with A = %d B = %d',selA,selB))

%% Plot the fields 3D
% close all
figure
orthosliceViewer(mtMat);
title('Remi - MT intensity')
figure
orthosliceViewer(shgMat);
title('Remi - SHG Signal')
figure
orthosliceViewer(polMat);
clim([0 2])
colorbar
title(sprintf('Polarity Signal with A = %d B = %d',selA,selB))

%% Save
save(fullfile(dataDir,[saveName '.mat']),'selA','selB','polMat','sampleT','highPolarVal')
save3DTiff(uint16(polMat*100),fullfile(dataDir,[saveName '.tif']))

%% View SHG and MT sums over time
sumInts = squeeze(sum(sum(densityField,1),2));
sumSHG = squeeze(sum(sum(selSHG,1),2));
figure
yyaxis left
plot(sumInts)
ylabel('Intensity')
yyaxis right
plot(sumSHG);
ylabel('SHG')

