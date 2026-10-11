function [outMat] = returnSmoothBlobsIDed(inMat,layerMean,layerWidth,gKern,calcSpeed)
%RETURNSMOOTHBLOBSIDED Generate smooth boundaries for objects in a grayscale
% matrix inMat. Contiguous objects in inMat should be labeled with unique
% integer values, ie via bwlabel or some analog.
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
% calcSpeed can be 'fast' or 'slow':
% calcSpeed = 'fast' will asign values to boundaries via direct dilation of
% the input image. This may not be desirable in the event that objects are
% too close. 
% calcSpeed = 'slow' will calculate boundaries individually before
% concatenating all objects together.
% NOTE: for best results, the voxel dimensions of inMat should be equal in
% all dimensions (cubic).
%2025-04-18 - Rémi Boros
% Reimplemented 2026-06-11

% Compatibility wrapper added 2026-10-10. Mask cleanup now resides in
% SegmentationTools; this path remains available to existing callers.
outMat = segmentationtools.cleanup.returnSmoothBlobsIDed( ...
    inMat,layerMean,layerWidth,gKern,calcSpeed);

end

