function [cropTif] = farmCropTiffSave(inputTif,topCorner,winSize,saveBool,saveDirFull)
%FARMCROPTIFFSAVE Take in tif, crop dims, and return tif. Boolean value allows
%user to save in a given directory (inluding file name) SAVEDIRFULL

% Ensure there are enough variables
if nargin < 5
    saveBool = 0;
end

% Crop tif
if numel(size(inputTif)) == 2
    cropTif = inputTif(topCorner(2)+(1:winSize(2)) - 1,topCorner(1) + (1:winSize(1)) - 1);
elseif numel(size(inputTif)) == 3
    cropTif = inputTif(topCorner(2) + (1:winSize(2)) - 1,topCorner(1)+(1:winSize(1)) - 1,topCorner(3) + (1:winSize(3)) - 1);
end

% Save tif, if requested
if saveBool == 1
    farmWriteTiff(cropTif,saveDirFull);
end

end

