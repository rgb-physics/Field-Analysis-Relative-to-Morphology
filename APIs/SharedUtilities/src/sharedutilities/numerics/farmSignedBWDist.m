function [outMat] = farmSignedBWDist(inMat)
%FARMSIGNEDBWDIST Calculate signed voxel distance with zero inside boundary.
% Inputs:
%   inMat    Binary foreground matrix or volume.
% Outputs:
%   outMat   Signed distance: negative inside, positive outside, zero on
%            the foreground-side boundary under the historical convention.
%
% See also farmObjectDistanceGradients, farmReturnSmoothBoundsBW

% 2026-04-28 - Rémi Boros

posMat = bwdist(inMat);
negMatPre = bwdist(~inMat);
% Enforce zero layer by shifting negMat by 1
negMat = farmConsMatLnB(negMatPre - 1,inMat);
% Combine matrices 
outMat = posMat - negMat;

end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Preserves bwdist(inMat) minus the foreground-only (bwdist(~inMat) - 1).
% The foreground-side subtraction gives zero at its boundary. This is not
% an exact signed distance to a continuous surface between voxel centers.
%
% EXAMPLE
% -------------------------------------------------------------------------
% mask = false(9, 9);
% mask(3:7, 3:7) = true;
% distance = farmSignedBWDist(mask);
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Distance is in voxel units on the array grid. No spacing correction,
% smoothing, resampling or implicit physical-unit conversion is performed.

