function [objSizes, objVoxels, objIDs] = farmGetCCVectors(currCC)
%FARMGETCCVECTORS Concatenated indices with LOCAL component-position IDs.
% Inputs:
%   currCC          Connected-component structure with PixelIdxList.
% Outputs:
%   objSizes        Voxel counts per component.
%   objVoxels       Concatenated component voxel indices.
%   objIDs          Local component-position IDs corresponding to the concatenated indices.

cells = cellfun(@(x)x(:), currCC.PixelIdxList(:), 'UniformOutput', false);
objSizes = farmCellIndSizes(cells);
if isempty(cells)
    objVoxels = zeros(0, 1);
    objIDs = zeros(0, 1);
    return
end
objVoxels = vertcat(cells{:});
objIDs = farmGenLenVec(1:numel(objSizes), objSizes);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGETCCVECTORS Concatenated indices with LOCAL component-position IDs.
% IDs are not persistent labels. Row/column PixelIdxList cell arrays are accepted.
