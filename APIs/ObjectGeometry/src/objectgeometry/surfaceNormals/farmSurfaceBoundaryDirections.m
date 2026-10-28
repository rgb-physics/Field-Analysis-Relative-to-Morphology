function [directions, info] = farmSurfaceBoundaryDirections(mask, indices, varargin)
%FARMSURFACEBOUNDARYDIRECTIONS Seed references from interior toward background.
% Inputs: binary YXZ mask, selected source linear indices; Spacing=[dY dX dZ].
% Outputs: N-by-3 unit XYZ reference directions and distance-metric metadata.
% Computes one bwdist closest-background map, not three full gradient arrays.
% Exterior is background; one-voxel padding handles full masks and edges.
% The nearest background is chosen in VOXEL distance, then displacement is
% converted to physical coordinates. With anisotropy this is an approximate
% sign reference, NOT a physical nearest-boundary direction or thickness.
% Equidistant sides are arbitrarily selected. Use to seed spatial orientation
% only; do not independently force every medial normal toward its nearest side.
p = inputParser; addParameter(p,'Spacing',[1 1 1]); parse(p,varargin{:});
spacing = p.Results.Spacing;
validateattributes(spacing,{'numeric'},{'vector','numel',3,'positive','real','finite'});
validateattributes(mask,{'logical','numeric'},{'real','finite','nonsparse'});
if ndims(mask)>3 || any(mask(:)~=0 & mask(:)~=1)
    error('objectgeometry:InvalidMask','Provide one binary YXZ mask.');
end
if ~isempty(indices)
    validateattributes(indices,{'numeric'},{'vector','integer','finite','positive','<=',numel(mask)});
end
indices = indices(:);
if any(~mask(indices)), error('objectgeometry:SurfaceIndices','Query indices must be inside material.'); end
directions = zeros(numel(indices),3);
if ~isempty(indices)
    padded = padarray(logical(mask),[1 1 1],false,'both');
    [~,nearest] = bwdist(~padded);
    [r,c,z] = ind2sub(size(mask),indices);
    sites = sub2ind(size(padded),r+1,c+1,z+1);
    [br,bc,bz] = ind2sub(size(padded),double(nearest(sites)));
    directions = double([bc-c-1,br-r-1,bz-z-1]).*double(spacing([2 1 3]));
    directions = directions./sqrt(sum(directions.^2,2));
end
info = struct('Metric','voxel-Euclidean','Spacing',spacing, ...
    'Purpose','component seed sign only','PaddedExterior',true);
end
