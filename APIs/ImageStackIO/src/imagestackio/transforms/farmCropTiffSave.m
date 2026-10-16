function [cropTif] = farmCropTiffSave(inputTif, topCorner, winSize, saveBool, saveDirFull)
%FARMCROPTIFFSAVE Crop an image array and optionally write it as TIFF.
% Inputs:
%   inputTif      Numeric 2D image or 3D volume, in YX or YXZ array order.
%   topCorner     One-based crop origin in XY or XYZ coordinate order.
%   winSize       Crop dimensions in XY or XYZ coordinate order.
%   saveBool      Write only when equal to 1 and all five inputs are given.
%   saveDirFull   Output TIFF path, including filename; optional when not saving.
% Outputs:
%   cropTif       Cropped array, retaining the input numeric type.
%
% See also farmWriteTiff

% Ensure there are enough variables
if nargin < 5
    saveBool = 0;
end

% Convert XY[Z] crop arguments to YX[Z] array indexing.
if numel(size(inputTif)) == 2
    cropTif = inputTif( ...
        topCorner(2) + (1:winSize(2)) - 1, ...
        topCorner(1) + (1:winSize(1)) - 1);
elseif numel(size(inputTif)) == 3
    cropTif = inputTif( ...
        topCorner(2) + (1:winSize(2)) - 1, ...
        topCorner(1) + (1:winSize(1)) - 1, ...
        topCorner(3) + (1:winSize(3)) - 1);
end

% Save tif, if requested
if saveBool == 1
    farmWriteTiff(cropTif, saveDirFull);
end


end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Supplying fewer than five arguments disables writing, even if the fourth
% argument is 1. Array indexing reports out-of-bounds crops; no clipping or
% padding is performed. Writing uses farmWriteTiff's defaults and validation.
%
% EXAMPLE
% -------------------------------------------------------------------------
% image = reshape(uint16(1:120), [10 12]);
% cropped = farmCropTiffSave(image, [3 2], [4 5]); % 5 rows, 4 columns
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Crop coordinates and sizes are in voxels. No intensity conversion,
% resampling or calibration propagation is performed by this array helper.
