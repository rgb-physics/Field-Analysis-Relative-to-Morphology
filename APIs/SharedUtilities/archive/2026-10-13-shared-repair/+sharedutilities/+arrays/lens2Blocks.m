function [logicMat,validCoord1,validCoord2] = lens2Blocks(vecLens1,vecLens2)
%LENS2BLOCKS Takes in a vector corresponding to lengths and generates a
%sparse logic matrix with 1s at indices corresponding to sub-boxes running
%down the matrix's diagonal. The function can be used to calculate outer
%product operators on sets of vectors. The user can input a second array of
%vector lengths in vecLens2 if the outer products are to be performed on
%sets of vectors with different numbers of elements
% 2023-11-30

% Append zero for indexing
vecLens1 = [0 vecLens1];
if nargin == 1
    vecLens2 = vecLens1;
else
    vecLens2 = [0 vecLens2];
end

% Generate indices dividing collated trajectories when written as single vector
totInds1 = arrayCumSum(vecLens1); totInds2 = arrayCumSum(vecLens2);
indexProds = arrayfun(@(x) sum(vecLens1(1:x).*vecLens2(1:x)), 1:numel(vecLens1));

% Generate logical block matrix
validCoord1 = zeros(1, max(indexProds));
validCoord2 = validCoord1;
%Generate logical indices
for currBlock = 1:numel(totInds1)-1
    currRange1 = totInds1(currBlock)+1:totInds1(currBlock+1);
    currRange2 = totInds2(currBlock)+1:totInds2(currBlock+1);
    currInds = indexProds(currBlock)+1:indexProds(currBlock+1);
    [c1Mat, c2Mat] = meshgrid(currRange1,currRange2);
    validCoord1(currInds) = c1Mat(:);
    validCoord2(currInds) = c2Mat(:);
end

% Convert to sparse logic matrix
logicMat = sparse(validCoord1,validCoord2,ones(size(validCoord2)));

end

