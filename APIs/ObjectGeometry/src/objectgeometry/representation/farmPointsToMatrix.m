function [matrix,grid,info] = farmPointsToMatrix(points,grid,varargin)
%FARMPOINTSTOMATRIX Rasterize N-by-D voxel-coordinate rows on an explicit grid.
% Grid.Size is YX/YXZ. CoordinateOrder='XYZ' (XY for 2-D) or 'YXZ'.
% Coordinates are one-based current voxel positions, not physical coordinates.
% Rounding='nearest'|'floor'|'ceil'; BoundsPolicy='error'|'omit' after rounding.
% Sigma=0 returns logical occupancy; positive scalar/vector sigma in voxels
% returns Gaussian-smoothed double occupancy. Vector Sigma order is YX/YXZ.
% Threshold=[] retains occupancy; supplied threshold returns field>Threshold.
% Duplicate points occupy one voxel. Empty input must be zeros(0,D).
% Returns current grid and info recording options/counts. Does not alter points.
grid = farmOGRepresentationGrid(grid);
options = farmOGRasterOptions(varargin{:});
[indices,omitted] = farmOGRasterIndices(points,grid,options);
mask = false(grid.Size); mask(indices) = true;
matrix = farmOGBroadenRaster(mask,options,grid);
info = struct('Options',options,'InputPointCount',size(points,1), ...
    'OmittedPointCount',omitted,'RasterVoxelCount',nnz(mask));
end
