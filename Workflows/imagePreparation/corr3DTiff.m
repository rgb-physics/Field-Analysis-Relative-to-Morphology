% This script corrects 3D tifs, then prepares them for further analysis.
% The script assumes a relatively uniform sample at T=1. Optionally, bright
% spots can be removed prior to generating correction masks.
% Earliest frames are smoothed using a 3D Gaussian with a kernel size much
% larger than the pixel size. This generates a correction mask for any
% inhomogeneities in the background illumination profile. A second mask is
% generated from the median projection along z of earliest frames. This
% second mask will correct for pervasive smears on the optics in the focal
% plane. 
% 2026-01-22 - Rémi Boros

%% Input parameters
% Directory info
% allDirs = {'Session 88, Exp 2','Session 88, Exp 3','Session 88, Exp 4','Session 88, Exp 5'};

% for index = 1:numel(allDirs)
homeDir = allDirs{index};
newDir = homeDir;
rawDir = fullfile(homeDir,'0 Raw Tifs');    
cropDir = fullfile(newDir, '1 Cropped MATLAB');   
corrDir8bitBase = fullfile(newDir, '2 Downscaled For Ilastik 8bit');     
corrDirBleach = fullfile(newDir, '3 Illumination Bleach Corrected 16bit');     

% File name info
rawName = 'Time%06i_raw647.tif';
saveIndForm = 't%03i';      saveTagForm = '647';
croppedTag = 'cropped';
corr8bitTag = 'illCorr8bit';
corrBleachTag = 'illBleachCorr16bit';

% Select times to process
allTimes = 1:100;
bgTimes = 1:3;
% Parameters for analysis
pixSize = 11*2/40;          % [.37 .37 .7]
voxDimRescale = [pixSize pixSize 0.7];
% ilastikTrainRescale = voxDimRescale/voxDimRescale(3);     % Builds off of scaling above to rescale images before Ilastik segmentation (smaller images -> faster segmentation)
ilastikTrainRescale = voxDimRescale*1/3;     % Rescale cropped images for Ilastik segmentation (smaller images -> faster segmentation)
gKern = 24;     % Kernel of Gaussian blurring for illumination correction
% Image parameters
cropCorner = [1 15 1];
winSize = [778 786 69];
% load(fullfile(cropDir, "metadata.mat"), "cropCorner", "winSize", '-mat');

cutOffs8bit = [1, 5000];
% Save every tif? (saves cropped, unprocessed data)
saveAll = 0;

%% Make directories and base name tags
corrDir8bit = fullfile(corrDir8bitBase,saveTagForm);
mkdir(cropDir);
% mkdir(corrDir);
mkdir(corrDir8bit); mkdir(corrDirBleach); 
croppedName = sprintf('%s_%s_%s.tif',saveIndForm,croppedTag,saveTagForm);
corrName8bit =  sprintf('%s_%s_%s.tif',saveIndForm,corr8bitTag,saveTagForm);
corrNameBleach =  sprintf('%s_%s_%s.tif',saveIndForm,corrBleachTag,saveTagForm);

%% Crop and rescale images used for generating masks (early times) 
tic
if saveAll == 1
    currRange = (allTimes);
else
    currRange = bgTimes;
end
% Iterate through early frames, crop and rescale
for tInd = 1:numel(currRange)
    currT = currRange(tInd);
    currTif = tiffreadVolume(fullfile(rawDir,sprintf(rawName,currT)));
    winSize = min(winSize,size(currTif) - cropCorner);
    currCrop = cropTiffSave(currTif, cropCorner, winSize, 1, fullfile(cropDir,sprintf(croppedName,currT)));
    currScaled = imresize3(currCrop, size(currCrop).*voxDimRescale);
    if tInd == 1
        int1 = sum(currScaled(:));
        tifClass = class(currTif);
    end
        save(fullfile(cropDir, "metadata.mat"), "cropCorner", "winSize", '-mat')

end

%% Load early tifs used to calculate correction matrices
sumWght = 1/numel(bgTimes);
% Generate mean intensity profile from early times
for tInd = 1:numel(bgTimes)
    currT = bgTimes(tInd);
    currMat = double(tiffreadVolume(fullfile(cropDir,sprintf(croppedName,currT))));
    if tInd == 1
        % Generate storage matrix for all layers for dirt analysis
        bgMat = currMat*sumWght;
        matIntT1 = sum(currMat,'all');
        matVol = numel(bgMat);
    else
        intScale = matIntT1/sum(currMat,'all');       % Account for bleaching
        bgMat = bgMat + currMat*intScale*sumWght;
    end
end

%% Generate correction profile for inhomogenous illumination profile
padMode = 'replicate';
% Generate first pass mask from Gaussian blur
tempRS = imresize3(bgMat,size(bgMat).*voxDimRescale/min(voxDimRescale));
bgCorrPreRS = imgaussfilt3(tempRS,gKern,'Padding',padMode);
bgCorrPre = imresize3(bgCorrPreRS,size(bgMat));

% bgCorrPre = imgaussfilt3(bgMat,gKern,'Padding',padMode);

% Remove background profile, look for bright outliers, replace outliers
bgPass1 = bgMat./bgCorrPre*matIntT1/matVol;
outLiers = bgPass1 > prctile(bgPass1,97);
bgMatPatch = consMatLnB(bgMat,~outLiers) + consMatLnB(bgCorrPre,outLiers);

% Generate final pass background mask from another Gaussian blur
tempRS = imresize3(bgMatPatch,size(bgMat).*voxDimRescale/min(voxDimRescale));
bgCorrRS = imgaussfilt3(tempRS,20,'Padding',padMode);
bgCorr = imresize3(bgCorrRS,size(bgMat));

% bgCorr = imgaussfilt3(bgMatPatch,20,'Padding',padMode);
save3DTiff(cast(bgCorr,tifClass), fullfile(newDir,sprintf('BackgroundCorrectionMatrix_%s.tif',saveTagForm)));

%% Remove artifacts in the focal plane (ie smears and dirt)
bgHom = bgMat./bgCorr;
focalCorr = median(bgHom,3);
save3DTiff(cast(focalCorr,tifClass), fullfile(newDir,sprintf('FocalCorrectionMatrix_%s.tif',saveTagForm)));

%% Total correction matrix (in original pixel size)
totalCorr = bgCorr .* focalCorr / (matIntT1/matVol); 
% save(fullfile(homeDir,'TotalCorrectionMatrix.mat'),'totalCorr');
save3DTiff(cast(totalCorr*(matIntT1/matVol),tifClass), ...
    fullfile(newDir,sprintf('TotalCorrectionMatrix_%s.tif',saveTagForm)));    % NOTE: saved correction matrix is scaled by (matIntT1/matVol)
save(fullfile(newDir,sprintf('metadata_%s.mat',saveTagForm)),'matIntT1','matVol',"gKern",...
    'ilastikTrainRescale','pixSize','cropCorner','winSize','cutOffs8bit')
toc
pause(.1)
%% Iterate through time and save ill. corr. rescaled images
load(fullfile(cropDir, "metadata.mat"), "cropCorner", "winSize", '-mat');
for tInd = 1:numel(allTimes)
    currT = allTimes(tInd);
    % Load data
    if saveAll == 1
        currImg = double(tiffreadVolume(fullfile(cropDir, sprintf(croppedName, currT))));
    else
        if exist(fullfile(rawDir,sprintf(rawName,currT)),'file')
            currTif = tiffreadVolume(fullfile(rawDir,sprintf(rawName,currT)));
            currImg = double(cropTiffSave(currTif, cropCorner, winSize, 0));
        else
            continue
        end
    end 
    % Correct for bleaching
    blchScale = matIntT1/sum(currImg(:));
    % Apply correction matrix
    corrImg = currImg./totalCorr*blchScale;
    % Rescale for Ilastik 
    currCorr8bit = max(0, corrImg - cutOffs8bit(1))*255/abs(diff(cutOffs8bit));
    rs8Bit = imresize3(currCorr8bit,round(size(corrImg).*ilastikTrainRescale));
    % Save data
    save3DTiff(uint8(rs8Bit), fullfile(corrDir8bit, sprintf(corrName8bit, currT)));
    save3DTiff(cast(corrImg,tifClass), fullfile(corrDirBleach, sprintf(corrNameBleach, currT)));
end
% end