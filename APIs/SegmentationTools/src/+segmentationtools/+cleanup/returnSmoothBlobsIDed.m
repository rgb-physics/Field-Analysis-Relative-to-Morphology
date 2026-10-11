function outMat = returnSmoothBlobsIDed(inMat, layerMean, layerWidth, gKern, calcSpeed)
%RETURNSMOOTHBLOBSIDED Historical signed-distance cleanup for labeled masks.
%   CALCSPEED="fast" calculates one binary boundary and samples IDs from a
%   dilation. CALCSPEED="slow" processes each nonzero ID independently.
%   Voxels must be isotropic before the distance and sphere operations.

layerWidth = abs(layerWidth);
if strcmpi(calcSpeed, 'fast')
    boundMat = segmentationtools.cleanup.returnSmoothBlobsBW( ...
        inMat > 0, layerMean, layerWidth, gKern);
    outerBound = round(max([1, layerWidth, layerMean + layerWidth]));
    fillMat = imdilate(inMat, strel('sphere', outerBound));
    outMat = zeros(size(inMat), 'like', inMat);
    outMat(boundMat) = fillMat(boundMat);
elseif strcmpi(calcSpeed, 'slow')
    outMat = zeros(size(inMat), 'like', inMat);
    allIDs = unique(inMat(inMat > 0));
    for index = 1:numel(allIDs)
        currentID = allIDs(index);
        currentBoundary = segmentationtools.cleanup.returnSmoothBlobsBW( ...
            inMat == currentID, layerMean, layerWidth, gKern);
        outMat(currentBoundary) = currentID;
    end
else
    error('segmentationtools:InvalidCalculationMode', ...
        'calcSpeed must be "fast" or "slow".');
end
end
