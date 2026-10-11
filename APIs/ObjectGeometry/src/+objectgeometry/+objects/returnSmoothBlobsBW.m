function [outBounds] = returnSmoothBlobsBW(ogBW,layerMean,layerWidth,gKern)
%RETURNSMOOTHBLOBSSBW Generate smooth representations of objects
% in a binarized matrix ogBW.
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

% Compatibility wrapper added 2026-10-10. Mask cleanup now resides in
% SegmentationTools; this path remains available to existing callers.
outBounds = segmentationtools.cleanup.returnSmoothBlobsBW( ...
    ogBW,layerMean,layerWidth,gKern);

end

