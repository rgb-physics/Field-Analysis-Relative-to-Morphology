function [outMat] = farmReturnSmoothBoundsIDed(inMat,layerMean,layerWidth,gKern,calcSpeed)
%FARMRETURNSMOOTHBOUNDSIDED Label distance layers around input object IDs.
% Inputs:
%   inMat        Label matrix with positive IDs and zero background.
%   layerMean    Center of the signed-distance interval, in voxels.
%   layerWidth   Half-width of the interval; absolute value is used.
%   gKern        Gaussian standard deviation in voxels; zero skips smoothing.
%   calcSpeed    'fast' for union distance/dilation; 'slow' for per-ID layers.
% Outputs:
%   outMat       Selected layers carrying assigned input IDs.
%
% See also farmReturnSmoothBoundsBW

%2025-04-18 - Rémi Boros
% Reimplemented 2026-04-28

% Ensure width is positive
layerWidth = abs(layerWidth);

% 'fast' boundary assignment: calculate in one go via dilation
if matches(calcSpeed,'fast')
    % Binarize matrix
    bwMat = (inMat > 0);
    % Get boundaries from the binarized matrix
    boundMat = farmReturnSmoothBoundsBW(bwMat,layerMean,layerWidth,gKern);
    % Dilate the original matrix
    outerBound = round(max(layerWidth,layerMean+layerWidth));
    if ndims(inMat) == 2
        kernel = strel('disk', max(0, outerBound), 0);
    else
        kernel = strel('sphere', max(0, outerBound));
    end
    fillMat = imdilate(inMat,kernel);
    % Sample the dilated image on the constructed boundaries
    outMat = farmConsMatLnB(fillMat, boundMat);

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
        currBnd = farmReturnSmoothBoundsBW(currBlob, layerMean, layerWidth, gKern);
        outMat(currBnd) = currID;
    end
else
    error('objectgeometry:InvalidCalculationMode','calcSpeed must be fast or slow.');
end

end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% 'fast' uses a foreground-union distance selection and grayscale dilation.
% Nearby objects can influence ID assignment. 'slow' calculates a full-grid
% layer for each ID; later IDs overwrite earlier ones at overlapping layers.
% These historical modes are not scientifically interchangeable.
% Interval endpoints are excluded, following farmReturnSmoothBoundsBW.
%
% EXAMPLE
% -------------------------------------------------------------------------
% labels = zeros(20, 20);
% labels(5:8, 5:8) = 7;
% layers = farmReturnSmoothBoundsIDed(labels, 0, 2, 0, 'slow');
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Distance and Gaussian width are in voxel units. No spacing conversion occurs.
% Per-ID computation allocates full-grid arrays repeatedly.
