%% From .tifs of filaments and .h5s of in/on/out, prepare fil. properties
% GAVE UP COMBINING CODE
% 
% 2026-07-01 - Rémi Boros

% basestDir = '<redacted original absolute path>';
basestDir = 'Session 88';
subDirs = {'Exp 1', 'Exp 2', 'Exp 3', 'Exp 4 - Rmin Redo', 'Exp 5'};

for index = 1:numel(subDirs)

filIntsDir = fullfile(basestDir,subDirs{index},'3 Illumination Bleach Corrected 16bit');
filIntsName = 't%03i_illBleachCorr16bit_647.tif';
threshFilDir = fullfile(basestDir,subDirs{index},'6 Filament Data');
threshFilName = 'Time%06i_threshFils.tif';
% regSegDir = '<redacted original absolute path>';
regSegDir = 'Session 88';
regSegName = 't%03i_illCorr8bit_560_E%i_Probabilities Stage 2.h5';
segTifDir = fullfile(basestDir,subDirs{index},'4 Tracked Blobs\In On Out Segmentation');
segTifName = 'T%03i_CleanInOnOut.tif';

selTimes = 1:57;
ogVoxSize = [.55 .55 .7];
% selTimes = 1:57;

thKern = 1;             % Kernel size for tophat filter
cropBool = 0;       % define/load cropCorner and winSize variables, if requested
threshBnds = 20;        % Note: this is a threshold on the tophat-filtered image

% For saving in on out tifs
h5Chans = [1 2 3];
outInOnChans = [1 3 2];
chanVals = 85:85:255;
h5thresh = 0.33;
% 1 to distinguish drop interiors and boundaries, otherwise combine interiors and boundaries and compare to bg
inOnDist = 1;          

%% Threshold filaments (if not already done)
for tInd = 1:numel(selTimes)
    % Load data - check if file exists
    currT = selTimes(tInd);
    threshFile = fullfile(threshFilDir,sprintf(threshFilName,currT));
    % If a thresholded image does not exist, make one
    if ~exist(threshFile,'file')
        currFile = fullfile(filIntsDir,sprintf(filIntsName,currT));
        % If the input intensity file does not exist, skip this file
        if ~exist(currFile,'file')
            continue
        end
        currImg = double(tiffreadVolume(currFile));
        if cropBool == 1
            currImg = cropTiffSave(currImg, cropCorner, winSize, 0, '');    % This is where you need winSize and cropCorner
        end
        % Tophat filter 
        corrMat = -LOG(currImg,thKern);
        % Threshold
        bwObjs = imbinarize(corrMat,threshBnds);
        % Save thresholded image
        save3DTiff(uint8(255*bwObjs),fullfile(threshFilDir,sprintf(threshFilName,currT)));
    end
end
clear imgSize
if ~exist('imgSize','var')
    temp = tiffreadVolume(fullfile(filIntsDir,sprintf(filIntsName,1)));
    imgSize = size(temp);
    clear temp;
end
save(fullfile(threshFilDir,'metadata.mat'),'imgSize','thKern','threshBnds','selTimes','ogVoxSize');
    
%% Threshold segmented in, on, out .h5s, save as .tifs
load(fullfile(threshFilDir,'metadata.mat'),'imgSize','thKern','threshBnds','selTimes','ogVoxSize');

for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    % Load segmentation, if it exists
    segFile = fullfile(regSegDir,sprintf(regSegName,currT,index));
    % If the input intensity file does not exist, skip this file
    if ~exist(segFile,'file')
        continue
    end
    currH5 = loadH5(segFile,'/exported_data',h5Chans);
    % Define some parameters
    segSize = size(currH5);
    segPixSize = (imgSize./segSize(1:3)).*ogVoxSize;
    cubicVoxelsSegSize = round(segSize(1:3).*segPixSize);

% in, on, out properties
    % Separate into ins, outs, ons
    [cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(...
        imresize3_4mat(currH5, cubicVoxelsSegSize),outInOnChans,h5thresh,1,1);
    % Generate .tif to save
    outMat = cleanOuts*chanVals(outInOnChans(1)) + ...
        cleanIns*chanVals(outInOnChans(2)) + ...
        cleanOns*chanVals(outInOnChans(3));       
% Save .tif
    save3DTiff(uint8(outMat),fullfile(segTifDir,sprintf(segTifName,currT)));

end

end

