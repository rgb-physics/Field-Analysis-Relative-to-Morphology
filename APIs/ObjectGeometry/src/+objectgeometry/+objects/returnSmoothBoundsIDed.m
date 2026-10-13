function [outMat] = returnSmoothBoundsIDed(inMat,layerMean,layerWidth,gKern,calcSpeed)
%RETURNSMOOTHBOUNDSIDED Generate smooth boundaries for objects in a grayscale
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
% Reimplemented 2026-04-28

% Ensure width is positive
layerWidth = abs(layerWidth);

% 'fast' boundary assignment: calculate in one go via dilation
if matches(calcSpeed,'fast')
    % Binarize matrix
    bwMat = (inMat > 0);
    % Get boundaries from the binarized matrix
    boundMat = objectgeometry.objects.returnSmoothBoundsBW(bwMat,layerMean,layerWidth,gKern);
    % Dilate the original matrix
    outerBound = round(max(layerWidth,layerMean+layerWidth));
    if ndims(inMat)==2, kernel=strel('disk',max(0,outerBound),0);
    else, kernel=strel('sphere',max(0,outerBound)); end
    fillMat = imdilate(inMat,kernel);
    % Sample the dilated image on the constructed boundaries
    outMat = sharedutilities.arrays.consMatLnB(fillMat, boundMat);

% 'slow' boundary assignment: dilate and assign values for each object sep.
elseif matches(calcSpeed,'slow')
    outMat = zeros(size(inMat),'like',inMat);
    % Get unique object IDs
    allIDs = unique(inMat(inMat>0));
    % Iterate over each ID, individually calculate shell boundaries, assign
    for index = 1:numel(allIDs)
        currID = allIDs(index);
        currBlob = inMat == currID;
        % Construct boundary
        currBnd = objectgeometry.objects.returnSmoothBoundsBW(currBlob, layerMean, layerWidth, gKern);
        outMat(currBnd) = currID;
    end
else
    error('objectgeometry:InvalidCalculationMode','calcSpeed must be fast or slow.');
end

end

