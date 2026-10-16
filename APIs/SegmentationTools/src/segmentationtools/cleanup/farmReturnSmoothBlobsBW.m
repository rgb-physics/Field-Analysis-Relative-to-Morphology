function outBounds = farmReturnSmoothBlobsBW(ogBW, layerMean, layerWidth, gKern)
%FARMRETURNSMOOTHBLOBSBW Select the interior of a smoothed distance threshold.
% Inputs:
%   ogBW         Binary foreground matrix or volume.
%   layerMean    Signed-distance offset in voxel units.
%   layerWidth   Threshold allowance; absolute value is used.
%   gKern        Positive Gaussian standard deviation in voxels.
% Outputs:
%   outBounds    Logical selection below layerMean + abs(layerWidth).
%
% See also farmSignedBWDist, farmReturnSmoothBoundsBW

signedDist = farmSignedBWDist(ogBW);
layerWidth = abs(layerWidth);

if size(ogBW, 3) > 1
    smDist = imgaussfilt3(signedDist, gKern);
else
    smDist = imgaussfilt(signedDist, gKern);
end

outBounds = smDist < (layerMean + layerWidth);
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Smooths the signed-distance field, then selects every value strictly below
% the threshold. There is no lower cutoff: this returns an interior region,
% not a finite-thickness boundary layer. Unlike farmReturnSmoothBoundsBW,
% this implementation always calls Gaussian smoothing, even for gKern=0;
% supported sigma values are determined by imgaussfilt/imgaussfilt3.
%
% EXAMPLE
% -------------------------------------------------------------------------
% mask = false(16, 16);
% mask(5:12, 5:12) = true;
% cleaned = farmReturnSmoothBlobsBW(mask, 0, 1, 1);
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Distances and smoothing use voxel units. A physical interpretation assumes
% isotropic voxels; no anisotropic correction or resampling is performed.
