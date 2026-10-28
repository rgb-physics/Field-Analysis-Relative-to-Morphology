function [points, indices, info] = farmMaskToPoints(mask, varargin)
%FARMMASKTOPOINTS Convert nonzero YXZ voxels to calibrated XYZ coordinates.
% Inputs:
%   mask       Logical/numeric YX or YXZ support (nonzero means selected).
%   Spacing    Positive [dY dX dZ], default [1 1 1].
%   Origin     Physical XYZ position of voxel (1,1,1), default [1 1 1].
% Outputs:
%   points     N-by-3 physical XYZ coordinates in find(mask) order.
%   indices    N-by-1 source linear indices, for direct field sampling.
%   info       Grid and coordinate convention, sufficient to invert mapping.
% Formula: XYZ = Origin + (voxelXYZ - 1).*Spacing([2 1 3]).
% No resampling, thinning, or source data mutation is performed.
p = inputParser;
addParameter(p,'Spacing',[1 1 1]);
addParameter(p,'Origin',[1 1 1]);
parse(p,varargin{:});
validateattributes(mask,{'logical','numeric'},{'real','finite','nonsparse'});
if ndims(mask)>3, error('objectgeometry:InvalidMask','Use one YX/YXZ support.'); end
spacing = p.Results.Spacing; origin = p.Results.Origin;
validateattributes(spacing,{'numeric'},{'real','finite','positive','vector','numel',3});
validateattributes(origin,{'numeric'},{'real','finite','vector','numel',3});
spacing = double(spacing(:).'); origin = double(origin(:).');
indices = find(mask ~= 0);
[row,col,depth] = ind2sub(size(mask),indices);
points = origin + (double([col,row,depth])-1).*spacing([2 1 3]);
info = struct('Size',[size(mask,1),size(mask,2),size(mask,3)], ...
    'Spacing',spacing,'Origin',origin,'CoordinateOrder','XYZ', ...
    'SpacingOrder','YXZ','OriginConvention','voxel (1,1,1) center');
end
