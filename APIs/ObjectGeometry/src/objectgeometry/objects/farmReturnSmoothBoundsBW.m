function [outBounds] = farmReturnSmoothBoundsBW(ogBW, layerMean, layerWidth, gKern)
%FARMRETURNSMOOTHBOUNDSBW Select a layer around a smoothed signed-distance level.
% Inputs:
%   ogBW         Binary foreground matrix or volume.
%   layerMean    Center of the distance interval, in voxels.
%   layerWidth   Half-width of the interval; absolute value is used.
%   gKern        Gaussian standard deviation in voxels; zero skips smoothing.
% Outputs:
%   outBounds    Logical selection on the input grid.
%
% See also farmSignedBWDist, farmGenerateGeometry

%2025-04-18 - Rémi Boros
% Reimplemented 2026-04-28

% Define the signed-distance transform
signedDist = farmSignedBWDist(ogBW);
layerWidth = abs(layerWidth);

% Smooth with a Gaussian kernel
if gKern == 0
    smDist = signedDist;
elseif size(ogBW,3) > 1
    smDist = imgaussfilt3(signedDist,gKern);
else
    smDist = imgaussfilt(signedDist,gKern);
end

% Isolate contour centered around layerMean with half-width layerWidth
outBounds = (smDist > (layerMean - layerWidth)) & (smDist < (layerMean + layerWidth));

end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Gaussian smoothing is applied to farmSignedBWDist, not to the input mask.
% Selects strictly between layerMean - abs(layerWidth) and
% layerMean + abs(layerWidth). Endpoints are excluded; zero width selects
% no voxels. Negative layerMean selects toward the object's interior.
% This historical selection rule is preserved, not a new profile-bin rule.
%
% EXAMPLE
% -------------------------------------------------------------------------
% mask = false(9, 9);
% mask(3:7, 3:7) = true;
% layer = farmReturnSmoothBoundsBW(mask, -1, 2, 0);
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Distances and smoothing use voxel units. Isotropic spacing is assumed for
% a physical-distance interpretation. No anisotropic correction is performed.
