%% This script takes in a segmentation matrix and generates a mask tif
% the mask is of an object defined through thresholding the contents of the
% segmentation logic matrix

% FilePath = '<redacted original absolute path>';
FilePath = 'Session 25, Exp 5';
% SaveDir = '<redacted original absolute path>';
SaveDir = 'Session 25, Exp 5';

FileNameFormat = 'Time000001_SegWeights.tif'; %The file name format
SaveNameFormat = 'Time000001_TopLayerGuess.tif';
channelNum = 2; cutoffVal = .4;
xSpace = 1; ySpace = 1; zSpace = 1;

%% Load data
segData = tiffreadVolume(fullfile(FilePath,FileNameFormat));

%% Generate mask
bwImg = imbinarize(segData, cutoffVal);
bwImg(:,:,[1:35, 85:end]) = 0;
bwObjs = bwconncomp(bwImg);

%Get largest object index
numPixels = cellfun(@numel,bwObjs.PixelIdxList);
[~,largeObjInd] = max(numPixels);
largestObj = bwObjs.PixelIdxList(largeObjInd);

% Make mask
outMask = zeros(size(bwImg));
outMask(largestObj{1}) = 1;
outMask = uint8(outMask);

%% Save mask
for zLayer = 1:size(outMask,3)
    if zLayer == 1
        imwrite(outMask(:,:,zLayer), fullfile(SaveDir, SaveNameFormat));
    else
        imwrite(outMask(:,:,zLayer), fullfile(SaveDir,SaveNameFormat), 'WriteMode','append');
    end
end


