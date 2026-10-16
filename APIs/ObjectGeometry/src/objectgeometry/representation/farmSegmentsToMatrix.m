function [matrix, grid, info] = farmSegmentsToMatrix(starts, ends, grid, varargin)
%FARMSEGMENTSTOMATRIX Rasterize N-by-D start/end coordinate rows as occupancy.
% Inputs:
%   starts          N-by-D segment-start coordinates.
%   ends            Matching N-by-D segment-end coordinates.
%   grid            Current grid metadata including Size in YX or YXZ order.
%   varargin        Coordinate, rounding, smoothing and threshold options.
% Outputs:
%   matrix          Occupancy or thresholded rendering of the segments.
%   grid            Current output grid metadata.
%   info            Rendering settings and sample counts.

grid = farmOGRepresentationGrid(grid);
options = farmOGRasterOptions(varargin{:});
validateattributes(starts, {'numeric'}, {'2d', 'real', 'finite'});
validateattributes(ends, {'numeric'}, {'2d', 'real', 'finite', 'size', size(starts)});
if size(starts, 2) ~= numel(grid.Size)
    error('objectgeometry:PointDimensions', 'Segment rows must match grid dimensions.');
end
mask = false(grid.Size);
omitted = 0;
for k = 1:size(starts, 1)
    a = double(starts(k, :));
    delta = double(ends(k, :)) - a;
    steps = ceil(2 * max(abs(delta)));
    if steps == 0
        points = a;
    else
        points = a + linspace(0, 1, steps + 1).' * delta;
    end
    [indices, count] = farmOGRasterIndices(points, grid, options);
    mask(indices) = true;
    omitted = omitted + count;
end
matrix = farmOGBroadenRaster(mask, options, grid);
info = struct('Options', options, 'InputSegmentCount', size(starts, 1), ...
              'OmittedSampleCount', omitted, 'RasterVoxelCount', nnz(mask));
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMSEGMENTSTOMATRIX Rasterize N-by-D start/end coordinate rows as occupancy.
% Same grid/options/coordinate convention as pointsToMatrix. Line endpoints
% included; interpolate at <=0.5 voxel in each coordinate, then round/deduplicate.
% This is a visualization raster, not exact voxel-intersection/supercover geometry.
% BoundsPolicy=omit discards out-of-grid raster samples (clips the display).
% Gaussian Sigma/optional Threshold act on union occupancy, never object IDs.
% Zero-length segments render as points. Empty arrays must be zeros(0,D).
