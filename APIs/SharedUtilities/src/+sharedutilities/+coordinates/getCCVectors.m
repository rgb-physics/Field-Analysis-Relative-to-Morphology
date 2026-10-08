function [objSizes,objVoxels,objIDs] = getCCVectors(currCC)
%GETCCVECTORS Takes in a connected components object currCC with a field
%PixelIdxList. PixelIdxList is a cell of vectors, each containing a set of
%scalars corresponding to matrix indices wherein each connected component
%is defined. Returns vectors of concatenated connected component sizes,
% indices, and a string of component IDs for indexing
% 2024-08-16 Rémi Boros

voxelIdxCell = currCC.PixelIdxList;
objSizes = cellIndSizes(voxelIdxCell');
objVoxels = vertcat(voxelIdxCell{:});
objIDs = genLenVec(1:numel(objSizes),objSizes);

end

