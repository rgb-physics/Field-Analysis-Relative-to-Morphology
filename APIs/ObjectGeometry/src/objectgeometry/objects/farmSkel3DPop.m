function [ptCloud, orMat, andMat] = farmSkel3DPop(inputMat, andOrFrac, cutOff, orMat, andMat, preferredAxis)
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

% PREFERREDAXIS is optional ('Z' by default), used when masks are computed.
% Output is a double voxel support, not an N-by-3 coordinate array.
% Set rng before calling to reproduce historical random sampling.
if nargin < 2 || isempty(andOrFrac), andOrFrac = 0.5; end
if nargin < 3 || isempty(cutOff), cutOff = 2; end
if nargin < 6, preferredAxis = 'Z'; end
validateattributes(andOrFrac, {'numeric'}, {'real','finite','scalar','nonnegative'});
validateattributes(cutOff, {'numeric'}, {'real','finite','scalar','nonnegative'});
if nargin < 5 || isempty(orMat) || isempty(andMat)
    [orMat, andMat] = farmSkel3Dfrom2D(inputMat, preferredAxis);
elseif ~isequal(size(orMat),size(inputMat),size(andMat))
    error('objectgeometry:MaskSize','Skeleton masks must match inputMat.');
end

% Populate matrix with random subpopulation of or matrix
segDist = bwdist(~inputMat);
cutoffOR = find(orMat & segDist >= cutOff);
sampLen = min(numel(cutoffOR), numel(find(andMat))*andOrFrac );
sampleCount = min(numel(cutoffOR),round(sampLen));
subSampOR = cutoffOR(randperm(numel(cutoffOR),sampleCount));
ptCloud = farmConsMatLnB(ones(size(inputMat)),[subSampOR; find(andMat)]);

end

