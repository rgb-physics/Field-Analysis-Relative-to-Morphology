function [outBounds] = returnSmoothBoundsBW(ogBW,layerMean,layerWidth,gKern)
%RETURNSMOOTHBOUNDSBW Generate smooth boundaries for objects in a binarized
% matrix ogBW.
% Smoothing is implemented via gaussian smoothing of the
% distance transform of the input matrix to circumvent pixelated artifacts
% in low-resolution images. 
% The bounding shell is generated a distance layerMean from blob boundaries
% with a half-width of layerWidth. layerMean < 0 correspond to layers
% in blobs interiors.
% gKern is the kernel size used to smooth the distance transform via 
% Gaussian smoothing and outSize is the dims of the output matrix. 
% Negative values of gKern will define a pointcloud towards blob interiors 
% rather than their exterior
% NOTE: for best results, the voxel dimensions of ogBW should be equal in
% all dimensions (cubic).
%2025-04-18 - Rémi Boros
% Reimplemented 2026-04-28

% Define the signed-distance transform
signedDist = signedBWDist(ogBW);
layerWidth = abs(layerWidth);

% Smooth with a Gaussian kernel
if size(ogBW,3) > 1
    smDist = imgaussfilt(signedDist,gKern);
else
    smDist = imgaussfilt3(signedDist,gKern);
end

% Isolate contour centered around layerMean with half-width layerWidth
outBounds = (smDist > (layerMean - layerWidth)) & (smDist < (layerMean + layerWidth));

end


