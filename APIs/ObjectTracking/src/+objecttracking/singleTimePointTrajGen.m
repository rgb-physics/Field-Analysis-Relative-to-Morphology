function [matchIndices,pointerMat,matchDists,totalCost] = singleTimePointTrajGen(sourceCenters,targetCeters,cutOffVal)
%SINGLETIMEPOINTTRAJGEN Uses Munkre's Hungarian Algorithm to determine
%object trajectories/object linking between two frames. The object
%locations at both times should already be known and stored in
%SOURCECENTERS and TARGETCENTERS for t1 and t2, respectively. CUTOFFVAL is
%a scalar indicating the maximum distance two objects can be before being
%considered uncorrelated.
% This function relies on the external munkres assignment library: https://www.mathworks.com/matlabcentral/fileexchange/20328-munkres-assignment-algorithm
% Rémi Boros 02/10/2022, UCSB

if nargin == 2
   cutOffVal = Inf; 
end

%Build distance matrix
sqDiffDimMat = zeros(size(targetCeters,1), size(sourceCenters,1), size(targetCeters,2));
for currDim = 1:size(targetCeters,2)

    sqDiffDimMat(:,:,currDim) = (targetCeters(:,currDim) - sourceCenters(:,currDim)').^2; 

end
summedSqDiffMat = sum(sqDiffDimMat,3)';

% Find best traj candidates with munkres/hungarian algorithm
[ matchIndices, totalCost ] = munkres(summedSqDiffMat);

% Keep target_distances
matchDists = sqrt(summedSqDiffMat(matchIndices));

% Generate matching index pair array
[ogObjID, newObjID] = find(matchIndices == 1);
pointerMat = [ogObjID, newObjID];

% Filter trajectory candidates for distances above cut off value
toKeep = matchDists <= cutOffVal;
pointerMat = pointerMat(toKeep,:);
matchDists = matchDists(toKeep);
matchIndices = zeros(size(matchIndices));
pointerInds = sub2ind(size(matchIndices), pointerMat(:,1), pointerMat(:,2));
matchIndices(pointerInds) = 1;

end

