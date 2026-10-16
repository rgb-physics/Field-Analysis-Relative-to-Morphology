function [distMat, globalDistMat, regionFlip, primbgInds, secbgInds, primProximalInds] = ...
    farmDistTransFromBoundary(primChan, bgChan, secChan, dilateRad)
%FARMDISTTRANSFROMBOUNDARY Takes in three matrices PRIMCHAN, SECCHAN, and BGCHAN
% Inputs:
%   primChan        Logical primary-region selection.
%   bgChan          Logical background-region selection.
%   secChan         Optional logical secondary-region selection.
%   dilateRad       Optional morphological radius in voxels.
% Outputs:
%   distMat         Primary-proximity selected signed-distance field.
%   globalDistMat   Unrestricted signed distance to the constructed boundary selections.
%   regionFlip      Interior/exterior sign array.
%   primbgInds      Primary/background boundary selection.
%   secbgInds       Secondary/background boundary selection.
%   primProximalInds Locations at least as close to primary as secondary boundaries.

% Generate dummy secondary channel if not passed and dummy dilation radius
if nargin == 2
    secChan = false(size(primChan));
    dilateRad = 0;
elseif nargin == 3
    dilateRad = 3;
end
if numel(size(primChan)) == 2
    strelObj = strel('disk', dilateRad, 0);
elseif numel(size(primChan)) == 3
    strelObj = strel('sphere', dilateRad);
end

% Define indices in ROI that are not background
regionInds = primChan | secChan;
regionFlip = ~regionInds - regionInds;

% Get indices of layer boundaries and inside/outside domain bounds
secbgInds = (secChan & imopen(bgChan, strelObj));
primbgInds = (primChan & imdilate(bgChan, strelObj) & ~secbgInds);
ioDist = bwdist(secbgInds);
ooDist = bwdist(primbgInds);
% Less than means closer: get indices closer to prim indices than sec indices
primProximalInds = (ooDist <= ioDist);

% Distance transforms and distinguishing logic matrices
globalDistMat = bwdist(secbgInds | primbgInds) .* regionFlip;
distMat = farmConsMatLnB(globalDistMat, primProximalInds);

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMDISTTRANSFROMBOUNDARY Takes in three matrices PRIMCHAN, SECCHAN, and BGCHAN
% and returns a distance transform calculated from the boundary of
% primary and background, making sure to ignore indices closer to secondary
% than to primary. The three channels are expected to be logicals. The
% function performs a selective distance transform useful in instances when
% distance-based level sets will contain artifacts from neighboring sources.
% As such, SECCHAN is an optional input without which all indices in the
% matrix will be considered. DILATERAD is an optional scalar used as a
% radius of a strel object for morphological operators, if requested
% 2024-03-28 Flipped sign of regionflip so interior is negative
