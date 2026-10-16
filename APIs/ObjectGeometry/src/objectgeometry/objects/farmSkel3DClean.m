function [trimSkel] = farmSkel3DClean(inputMat,distCO)
%FARMSKEL3DCLEAN inputMat is a binarized matrix corresponding to vertices of
% a point cloud and distCO and scalar corresponding to a cutoff distance
% away from which said vertices will be removed.

% Define neighborhoods via cut off in dist transform space
objNBHoods = bwdist(inputMat) < distCO;
connComps = bwconncomp(objNBHoods);
objs = connComps.PixelIdxList;
objSizes = cell2mat(cellfun(@size,objs,'UniformOutput',false)');
% Isolate objects larger than a std larger than median object size
bigObjs = objs(objSizes(:,1) > (median(objSizes(:,1)) + std(objSizes(:,1))) );
% Reconstruct logic matrix with appropriately sized objects only
trimInds = vertcat(bigObjs{:});
ogInds = find(inputMat(:)==1);
allInds = intersect(trimInds, ogInds);
trimSkel = zeros(size(inputMat));
trimSkel(allInds) = 1;

end

