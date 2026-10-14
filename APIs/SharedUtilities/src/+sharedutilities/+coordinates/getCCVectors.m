function [objSizes,objVoxels,objIDs]=getCCVectors(currCC)
%GETCCVECTORS Concatenated indices with LOCAL component-position IDs.
% IDs are not persistent labels. Row/column PixelIdxList cell arrays are accepted.
cells=cellfun(@(x)x(:),currCC.PixelIdxList(:),'UniformOutput',false);
objSizes=sharedutilities.miscellaneous.cellIndSizes(cells);
if isempty(cells), objVoxels=zeros(0,1); objIDs=zeros(0,1); return; end
objVoxels=vertcat(cells{:});
objIDs=sharedutilities.coordinates.genLenVec(1:numel(objSizes),objSizes);
end
