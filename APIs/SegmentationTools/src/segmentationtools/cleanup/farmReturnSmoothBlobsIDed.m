function outMat = farmReturnSmoothBlobsIDed(inMat, layerMean, layerWidth, gKern, calcSpeed)
%FARMRETURNSMOOTHBLOBSIDED Assign IDs to distance-cleaned object interiors.
% Inputs:
%   inMat        Label array with positive object IDs and zero background.
%   layerMean    Signed-distance offset in voxel units.
%   layerWidth   Threshold allowance; absolute value is used.
%   gKern        Positive Gaussian standard deviation in voxels.
%   calcSpeed    'fast' for foreground-union cleanup; 'slow' for per-ID cleanup.
% Outputs:
%   outMat       Cleaned label array with the same size and type as inMat.
%
% See also farmReturnSmoothBlobsBW

layerWidth = abs(layerWidth);

if strcmpi(calcSpeed, 'fast')
    boundMat = farmReturnSmoothBlobsBW( ...
        inMat > 0, layerMean, layerWidth, gKern);
    outerBound = round(max([1, layerWidth, layerMean + layerWidth]));
    fillMat = imdilate(inMat, strel('sphere', outerBound));
    outMat = zeros(size(inMat), 'like', inMat);
    outMat(boundMat) = fillMat(boundMat);
elseif strcmpi(calcSpeed, 'slow')
    outMat = zeros(size(inMat), 'like', inMat);
    allIDs = unique(inMat(inMat > 0));

    % Calculate each ID separately in the original ascending-ID order.
    for index = 1:numel(allIDs)
        currentID = allIDs(index);
        currentBoundary = farmReturnSmoothBlobsBW( ...
            inMat == currentID, layerMean, layerWidth, gKern);
        outMat(currentBoundary) = currentID;
    end
else
    error('segmentationtools:InvalidCalculationMode', ...
        'calcSpeed must be "fast" or "slow".');
end
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% 'fast' cleans the union of positive labels, then obtains IDs by grayscale
% dilation with a spherical element. Nearby objects can affect assignment.
% 'slow' cleans each ID separately; later IDs overwrite earlier IDs where
% selections overlap. These modes are not interchangeable measurements.
% Each cleanup selects a thresholded interior, not a boundary-only layer.
% Per-ID mode repeatedly allocates full-grid distance and smoothing arrays.
%
% EXAMPLE
% -------------------------------------------------------------------------
% labels = zeros(16, 16, 16, 'uint16');
% labels(5:12, 5:12, 5:12) = 7;
% cleaned = farmReturnSmoothBlobsIDed(labels, 0, 1, 1, 'slow');
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Voxel distances, smoothing and spherical dilation assume isotropic voxels
% for physical interpretation. No calibration or resampling is introduced.
