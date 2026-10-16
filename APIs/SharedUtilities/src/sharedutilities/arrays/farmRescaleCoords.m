function outCoords = farmRescaleCoords(inCoords, ogDims, newDims)
%FARMRESCALECOORDS Nearest output voxel centers for XYZ coordinates on YXZ grids.
% Inputs:
%   inCoords        XY or XYZ coordinate rows on the source grid.
%   ogDims          Original array dimensions in YX or YXZ order.
%   newDims         Destination array dimensions in YX or YXZ order.
% Outputs:
%   outCoords       Rounded/clamped destination voxel-center coordinates.

validateattributes(ogDims, {'numeric'}, {'vector', 'integer', 'positive', 'finite'});
validateattributes(newDims, {'numeric'}, {'vector', 'integer', 'positive', 'finite'});
ogDims = double(ogDims(:)');
newDims = double(newDims(:)');
nD = numel(ogDims);
if ~ismember(nD, [2 3]) || numel(newDims) ~= nD
    error('sharedutilities:Dimensions', 'Use matching YX/YXZ grid dimensions.');
end
validateattributes(inCoords, {'numeric'}, {'2d', 'real', 'finite'});
if size(inCoords, 2) ~= nD
    error('sharedutilities:Coordinates', 'Coordinates must be N-by-D in XY/XYZ order.');
end
points = double(inCoords);
points(:, [1 2]) = points(:, [2 1]);
if any(points(:) < 1) || any(any(points > ogDims))
    error('sharedutilities:Coordinates', 'Input coordinates must lie within the source grid.');
end
mapped = round((points - .5) .* (newDims ./ ogDims) + .5);
mapped = min(max(mapped, 1), newDims);
outCoords = mapped;
outCoords(:, [1 2]) = mapped(:, [2 1]);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMRESCALECOORDS Nearest output voxel centers for XYZ coordinates on YXZ grids.
% Maps (index-.5)*scale+.5, rounds, then clamps to valid output centers.
% This maps positions, not labels/IDs; duplicated output coordinates are possible.
% Update spacing/source-transform metadata in the caller after actual resampling.
