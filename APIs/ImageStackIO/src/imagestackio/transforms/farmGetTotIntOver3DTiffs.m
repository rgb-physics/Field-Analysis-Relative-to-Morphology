function [allInts] = farmGetTotIntOver3DTiffs(dataDir, dataNameForm, selectN)
%FARMGETTOTINTOVER3DTIFFS Sum voxel intensities in each selected TIFF volume.
% Inputs:
%   dataDir        Folder containing TIFF volumes.
%   dataNameForm   Filename pattern receiving each selectN value via sprintf.
%   selectN        Numeric file/frame selections in the desired order.
% Outputs:
%   allInts        Double totals with the same shape as selectN.
%
% See also farmReadTiff

allInts = zeros(size(selectN));

for nInd = 1:numel(selectN)

    currN = selectN(nInd);
    currTif = tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm, currN)));
    allInts(nInd) = sum(double(currTif(:)));

end


end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Loads and sums one volume per selection. Values are converted to double
% before summation. Repeated selections are read again. No intensity scaling,
% NaN/Inf filtering, time conversion or physical-volume weighting is applied.
% tiffreadVolume interprets the file; this helper does not select channels
% or stored time points using ImageStackIO metadata.
%
% EXAMPLE
% -------------------------------------------------------------------------
% totals = farmGetTotIntOver3DTiffs('C:/images', 't%03i.tif', [2 5]);
