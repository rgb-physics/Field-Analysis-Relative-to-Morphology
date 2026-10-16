function scaleInds = farmRescaleCoords_Inds(inputInds, ogDims, newDims)
%FARMRESCALECOORDS_INDS Map source voxel centers, preserving index-vector shape.
% Inputs:
%   inputInds       Linear source indices; row/column shape is retained.
%   ogDims          Original array dimensions in YX or YXZ order.
%   newDims         Destination array dimensions in YX or YXZ order.
% Outputs:
%   scaleInds       Destination linear indices with the input vector shape.

validateattributes(ogDims, {'numeric'}, {'vector', 'integer', 'positive', 'finite'});
validateattributes(newDims, {'numeric'}, {'vector', 'integer', 'positive', 'finite'});
ogDims = double(ogDims(:)');
newDims = double(newDims(:)');
nD = numel(ogDims);
if ~ismember(nD, [2 3]) || numel(newDims) ~= nD
    error('sharedutilities:Dimensions', 'Use matching YX/YXZ grids.');
end
if isempty(inputInds)
    scaleInds = zeros(size(inputInds));
    return
end
validateattributes(inputInds, {'numeric'}, {'vector', 'integer', 'positive', 'finite', '<=', prod(ogDims)});
subs = cell(1, nD);
[subs{:}] = ind2sub(ogDims, inputInds(:));
points = cat(2, subs{:});
points(:, [1 2]) = points(:, [2 1]);
mapped = farmRescaleCoords(points, ogDims, newDims);
mapped(:, [1 2]) = mapped(:, [2 1]);
subs = num2cell(mapped, 1);
scaleInds = reshape(sub2ind(newDims, subs{:}), size(inputInds));
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMRESCALECOORDS_INDS Map source voxel centers, preserving index-vector shape.
