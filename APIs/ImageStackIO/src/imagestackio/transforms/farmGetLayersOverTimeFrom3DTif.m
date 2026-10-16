function [layerStore] = farmGetLayersOverTimeFrom3DTif(dataDir, dataName, zSlices)
%FARMGETLAYERSOVERTIMEFROM3DTIF Read selected pages from one TIFF file.
% Inputs:
%   dataDir      Folder containing the TIFF.
%   dataName     TIFF filename, not a filename pattern.
%   zSlices      One-based page indices in the requested output order.
% Outputs:
%   layerStore   uint16 YX array stack with one page per requested index.
%
% See also farmReadTiff

% Read the first page for spatial dimensions, then allocate selected pages.
currTiff = imread(fullfile(dataDir, dataName), 1);
layerStore = uint16(zeros(size(currTiff, 1), size(currTiff, 2), numel(zSlices)));

% Read the requested pages in supplied order, including repeated indices.
for currZ = 1:numel(zSlices)
    layerStore(:, :, currZ) = imread(fullfile(dataDir, dataName), zSlices(currZ));
end


end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Despite the historical name, this function reads one file, not a time series.
% Assignment converts each page to uint16, including its rounding/saturation
% behavior for other input types. This conversion is preserved, not a claim
% that arbitrary input intensities are preserved quantitatively.
% No axis metadata or spatial calibration is returned.
%
% EXAMPLE
% -------------------------------------------------------------------------
% selected = farmGetLayersOverTimeFrom3DTif('C:/images', 'volume.tif', [3 1]);
