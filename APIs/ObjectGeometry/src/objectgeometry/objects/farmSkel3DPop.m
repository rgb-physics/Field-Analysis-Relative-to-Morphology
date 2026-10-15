function [ptCloud, orMat, andMat] = farmSkel3DPop(inputMat, andOrFrac, cutOff, orMat, andMat)
%FARMSKEL3DPOP Takes in a matrix, along with a cutoff value for scaling used
%to remove skeletonization vertices too far from the center of any 
%"structures" located in the input matrix. The input matrix is assumed to
%be binarized. orMat and andMat represent the union and intersection of the
%skeletonizations of the objects located in the input matrix. If not
%passed, these matrices are calculated. cutOff is in pixels (for bwdist).
%andOrFrac determines the number of indices to pull from orMat as a
%fraction of the number of non-zero indices in andMat.
% The function returns a point cloud comprised of the andMat and some
% number of indices pulled randomly from orMat, effectively populating the
% andMat with some subset of the orMat.

% Fix input variables
if nargin == 1
    andOrFrac = 0.5;
    cutOff = 2;
    [orMat, andMat] = farmSkel3Dfrom2D(inputMat);
elseif nargin == 2
    cutOff = 2;
    [orMat, andMat] = farmSkel3Dfrom2D(inputMat);
elseif nargin == 3
    [orMat, andMat] = farmSkel3Dfrom2D(inputMat);
end

% Populate matrix with random subpopulation of or matrix
segDist = bwdist(~inputMat);
cutoffOR = find(segDist.*orMat >= cutOff);
sampLen = min(numel(cutoffOR), numel(find(andMat))*andOrFrac );
sampleCount = min(numel(cutoffOR),round(sampLen));
subSampOR = cutoffOR(randperm(numel(cutoffOR),sampleCount));
ptCloud = farmConsMatLnB(ones(size(inputMat)),[subSampOR; find(andMat)]);

end

